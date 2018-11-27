defmodule CryptoCoin.FullNode do
  def start(chain, public_key, private_key, mining_reward, diff) do
    GenServer.start_link(
      __MODULE__,
      [
        chain: chain,
        public_key: public_key,
        private_key: private_key,
        mining_reward: mining_reward,
        diff: diff
      ],
      []
    )
  end

  def add_peer(pid, peerId) do
    GenServer.cast(pid, {:add_peer, peerId})
  end

  # Tries to extend the blockchain by including this
  # set of transactions into a new block.
  def confirm_trasaction(pid, transaction) do
    GenServer.cast(pid, {:confirm_trasaction, transaction})
  end

  # Private methods after this

  def init(opts) do
    {:ok, miner} = CryptoCoin.Miner.start(self())

    state = %{
      public_key: opts[:public_key],
      private_key: opts[:private_key],
      block_chain: %{},
      miner: miner,
      mining_reward: opts[:mining_reward],
      diffLevel: opts[:diff],
      peers: [],
      spent_utxos: MapSet.new([])
    }

    chain = opts[:chain]

    if chain == nil or CryptoCoin.Blockchain.chain_length(chain) == 0 do
      mine_genesis_block(state)
    else
      send(self(), {:handle_blockchain_broadcast, chain})
    end

    {:ok, state}
  end

  defp mine_genesis_block(state) do
    transaction = mining_reward_transaction(state)
    send(state.miner, {:mine, state.block_chain, [transaction], state.diffLevel})
  end

  defp mining_reward_transaction(state) do
    # create an empty transaction
    transaction = CryptoCoin.Transaction.create()
    # No input
    inputs = []
    transaction = CryptoCoin.Transaction.add_inputs(transaction, inputs)

    CryptoCoin.Transaction.add_transaction_output(
      transaction,
      state.public_key,
      state.mining_reward
    )
  end

  def handle_info({:handle_blockchain_broadcast, chain}, state) do
    # Update if the new chain is longer and if its valid.
    new_size = CryptoCoin.Blockchain.chain_length(chain)
    old_size = CryptoCoin.Blockchain.chain_length(state.block_chain)

    updated_state =
      if new_size > old_size and CryptoCoin.Blockchain.is_valid(chain) == true do
        # We are going to update the blockchain of this node.
        # Shutdown the miner and create a new one.
        # Update the blockchain.
        # TODO: Spent transactions update.
        reset_miner(state)
        notifyPeers(state.peers, chain)
        state |> Map.put(:block_chain, chain)
      else
        state
      end

    {:noreply, updated_state}
  end

  defp reset_miner(state) do
    # TODO: Kill miner?
    {:ok, miner} = CryptoCoin.Miner.start(self())
    state |> Map.put(:miner, miner)
  end

  # Returns false if the transaction contains units that are already spent
  defp is_valid_transaction(transaction, state) do
    inputs = CryptoCoin.Transaction.get_inputs(transaction)

    spent_units_set = state.spent_utxos
    valid_inputs = Enum.filter(inputs, fn(input) ->
      unique_id = CryptoCoin.TransactionUnit.get_unique_id(input)
      spent_units_set |> MapSet.member?(unique_id) == false
    end)

    length(valid_inputs) == length(inputs)
  end

  def handle_cast({:confirm_trasaction, transaction}, state) do
    # TODO: What if the miner is busy?
    # If the transaction is not valid, ignore it.
    updated_state =
      if CryptoCoin.Transaction.is_valid(transaction) == true and
           is_valid_transaction(transaction, state) == true do
        send(state.miner, {:mine, state.block_chain, [transaction], state.diffLevel})
        update_spent_transation_units(transaction, state)
      else
        state
      end

    {:noreply, updated_state}
  end

  defp update_spent_transation_units(transaction, state) do
    inputs = CryptoCoin.Transaction.get_inputs(transaction)

    set =
      Enum.reduce(inputs, state.spent_utxos, fn input, acc ->
        acc |> MapSet.put(CryptoCoin.TransactionUnit.get_unique_id(input))
      end)
    state |> Map.put(:spent_utxos, set)
  end

  def handle_cast({:add_peer, peerId}, state) do
    # Notify the new peer of our blockchain
    notifyPeers([peerId], state.block_chain)
    peers = state |> Map.get(:peers)
    peers = [peerId] ++ peers
    state = state |> Map.put(:peers, peers)
    {:noreply, state}
  end

  # Called when a miner finds a block matching the set diff level
  def handle_info({:found_a_block, blockchain, block}, state) do
    # Ignore the call if current block chain is not exactly
    # equal to the blockchain with miner. Could happen if the
    # node failed to kill miner after receiving a longer chain.
    updated_state =
      if CryptoCoin.Blockchain.is_equal(blockchain, state.block_chain) == true do
        chain = CryptoCoin.Blockchain.add(block, blockchain)
        # Notify other nodes that we found a new longer chain.
        notifyPeers(state |> Map.get(:peers), chain)
        state |> Map.put(:block_chain, chain)
      else
        state
      end

    {:noreply, updated_state}
  end

  defp notifyPeers(peers, chain) do
    if peers != nil and length(peers) > 0 do
      if CryptoCoin.Blockchain.chain_length(chain) != 0 do
        Enum.each(peers, fn pid ->
          if pid != nil do
            send(pid, {:handle_blockchain_broadcast, chain})
          end
        end)
      else
      end
    end
  end
end
