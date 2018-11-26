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

  def handle_blockchain_broadcast(pid, chain) do
    GenServer.cast(pid, {:handle_blockchain_broadcast, chain})
  end

  # Tries to extend the blockchain by including this
  # set of transactions into a new block.
  def confirm_trasactions(pid, trasactions) do
    GenServer.cast(pid, {:confirm_trasactions, trasactions})
  end

  # Private methods after this

  def init(opts) do
    {:ok, miner} = CryptoCoin.Miner.start(self())

    state = %{
      public_key: opts[:public_key],
      private_key: opts[:private_key],
      block_chain: opts[:chain],
      miner: miner,
      mining_reward: opts[:mining_reward],
      diffLevel: opts[:diff],
      peers: []
    }

    if CryptoCoin.Blockchain.chain_length(opts[:chain]) == 0 do
      mine_genesis_block(state)
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

  def handle_cast({:handle_blockchain_broadcast, _chain}, state) do
    # If the received chain is shorter than the one this node
    # currently has, ignore it.
    {:noreply, state}
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
