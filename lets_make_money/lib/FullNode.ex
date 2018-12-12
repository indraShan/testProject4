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

  def add_wallet(pid, walletId) do
    GenServer.cast(pid, {:add_wallet, walletId})
  end

  # Tries to extend the blockchain by including this
  # set of transactions into a new block.
  def confirm_trasaction(pid, transaction) do
    send(pid, {:confirm_trasaction, transaction})
  end

  def mine_genesis(pid, genesis_reward) do
    GenServer.cast(pid, {:mine_genesis, genesis_reward})
  end

  def set_topology(pid, topology) do
    GenServer.cast(pid, {:set_topology, topology})
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
      wallets: [],
      # transaction_hash -> transaction_object
      processing_transactions: %{},
      # id -> {bool, amount}. true means the unit is spent already
      trasaction_units_map: %{},
      topology: nil
    }

    chain = opts[:chain]

    if CryptoCoin.Blockchain.chain_length(chain) != 0 do
      send(self(), {:handle_blockchain_broadcast, chain, self()})
    end

    {:ok, state}
  end

  defp mine_genesis_block(state, genesis_reward) do
    transaction = mining_reward_transaction(state, genesis_reward)
    send(state.miner, {:mine, state.block_chain, [transaction], state.diffLevel})
  end

  defp mining_reward_transaction(state, reward) do
    # create an empty transaction
    transaction = CryptoCoin.Transaction.create()
    # No input
    inputs = []
    transaction = CryptoCoin.Transaction.add_inputs(transaction, inputs)

    CryptoCoin.Transaction.add_transaction_output(
      transaction,
      state.public_key,
      reward
    )
  end

  def handle_info({:handle_blockchain_broadcast, chain, caller}, state) do
    # Update if the new chain is longer and if its valid.
    new_size = CryptoCoin.Blockchain.chain_length(chain)
    old_size = CryptoCoin.Blockchain.chain_length(state.block_chain)

    updated_state =
      if (new_size > old_size and CryptoCoin.Blockchain.is_valid(chain) == true) or
           (new_size == old_size and CryptoCoin.Blockchain.is_older_than(chain, state.block_chain) and
              CryptoCoin.Blockchain.is_valid(chain) == true) do
        # We are going to update the blockchain of this node.
        # Shutdown the miner and create a new one.
        miner = reset_miner(state)
        state = state |> Map.put(:miner, miner)
        # Update utxo references.
        transactions = CryptoCoin.Blockchain.get_trasactions(chain)

        transaction_units_map =
          update_transaction_units_map_for_transactions(transactions, state.trasaction_units_map)

        state = state |> Map.put(:trasaction_units_map, transaction_units_map)
        notify_block_chain(chain, state)
        # Mining might have been interrupted because of arrival of this blockchain.
        # In that case try to confirm pending transactions once again.
        confirm_interrupted_transactions(state)
        # Update the blockchain.
        state |> Map.put(:block_chain, chain)
      else
        # For whatever reason this nodes chain has persisted.
        # If the two chains are not the same, ask the peer who sent
        # this broadcast, to update its chain.
        if CryptoCoin.Blockchain.is_equal(chain, state.block_chain) == false && caller != self() do
          send(caller, {:handle_blockchain_broadcast, state.block_chain, self()})
        end

        state
      end

    {:noreply, updated_state}
  end

  defp confirm_interrupted_transactions(state) do
    transactions = state.processing_transactions |> Map.values()

    Enum.each(transactions, fn transaction ->
      CryptoCoin.FullNode.confirm_trasaction(self(), transaction)
    end)
  end

  defp update_transaction_units_map_for_transactions(transactions, transaction_units_map) do
    Enum.reduce(transactions, transaction_units_map, fn transaction, acc ->
      update_transaction_units_map(transaction, acc)
    end)
  end

  defp reset_miner(state) do
    Process.exit(state.miner, :normal)
    {:ok, miner} = CryptoCoin.Miner.start(self())
    miner
  end

  # Returns false if the transaction contains units that are already spent
  defp transaction_does_not_double_spend(transaction, state) do
    inputs = CryptoCoin.Transaction.get_inputs(transaction)

    units_map = state.trasaction_units_map

    valid_inputs =
      Enum.filter(inputs, fn input ->
        unique_id = CryptoCoin.TransactionUnit.get_unique_id(input)
        {spent, _} = units_map |> Map.get(unique_id)
        spent == false
      end)

    length(valid_inputs) == length(inputs)
  end

  # Returns false if the transaction uses a input that is not known to
  # the node. i.e. return false if the inputs to the transaction is
  # not present in the trasaction_units_map variable or if the amount
  # of the known unit does not match the amount in the unit inside the
  # transaction.
  defp transaction_does_not_spend_unknown_unit(transaction, state) do
    inputs = CryptoCoin.Transaction.get_inputs(transaction)

    units_map = state.trasaction_units_map

    valid_inputs =
      Enum.filter(inputs, fn input ->
        unique_id = CryptoCoin.TransactionUnit.get_unique_id(input)
        is_known_unit = units_map |> Map.has_key?(unique_id) == true

        if is_known_unit == true do
          {_, amount} = units_map |> Map.get(unique_id)
          amount == CryptoCoin.TransactionUnit.get_amount(input)
        else
          is_known_unit
        end
      end)

    length(valid_inputs) == length(inputs)
  end

  def handle_cast({:mine_genesis, genesis_reward}, state) do
    mine_genesis_block(state, genesis_reward)
    {:noreply, state}
  end

  def handle_cast({:set_topology, topology}, state) do
    # Notify peers if we have a valid blockchain
    updated_state = state |> Map.put(:topology, topology)
    notify_block_chain(state.block_chain, updated_state)
    {:noreply, updated_state}
  end

  def handle_info({:confirm_trasaction, transaction}, state) do
    # If the transaction is not valid, don't mine for it.
    updated_state =
      if CryptoCoin.Transaction.is_valid(transaction) == true and
           transaction_does_not_spend_unknown_unit(transaction, state) == true and
           transaction_does_not_double_spend(transaction, state) == true do
        mining_transaction = mining_reward_transaction(state, state.mining_reward)

        send(
          state.miner,
          {:mine, state.block_chain, [transaction, mining_transaction], state.diffLevel}
        )

        # Ask other nodes to confirm the transaction too.
        notify_transaction(transaction, state)

        # record this transaction as 'processing'
        transaction_hash = CryptoCoin.Utils.hash(CryptoCoin.Utils.encode(transaction))

        processing_transactions =
          state.processing_transactions |> Map.put(transaction_hash, transaction)

        state |> Map.put(:processing_transactions, processing_transactions)
      else
        # If the transaction is invalid, it should be removed from
        # processing_transactions if present
        transaction_hash = CryptoCoin.Utils.hash(CryptoCoin.Utils.encode(transaction))
        processing_transactions = state.processing_transactions |> Map.delete(transaction_hash)
        state |> Map.put(:processing_transactions, processing_transactions)
      end

    {:noreply, updated_state}
  end

  defp update_transaction_units_map(transaction, transaction_units_map) do
    # Update spent units
    inputs = CryptoCoin.Transaction.get_inputs(transaction)

    map =
      Enum.reduce(inputs, transaction_units_map, fn input, acc ->
        unique_id = CryptoCoin.TransactionUnit.get_unique_id(input)
        amount = CryptoCoin.TransactionUnit.get_amount(input)
        acc |> Map.put(unique_id, {true, amount})
      end)

    # Updates units created during this transaction
    outputs = CryptoCoin.Transaction.get_outputs(transaction)

    Enum.reduce(outputs, map, fn output, acc ->
      unique_id = CryptoCoin.TransactionUnit.get_unique_id(output)
      amount = CryptoCoin.TransactionUnit.get_amount(output)
      acc |> Map.put(unique_id, {false, amount})
    end)
  end

  def handle_cast({:add_wallet, walletId}, state) do
    # Notify the new wallet of our blockchain
    notify_block_chain_to_peers(state.block_chain, [walletId])
    wallets = state |> Map.get(:wallets)
    wallets = [walletId] ++ wallets
    {:noreply, state |> Map.put(:wallets, wallets)}
  end

  # Called when a miner finds a block matching the set diff level
  def handle_info({:found_a_block, blockchain, block, transactions}, state) do
    # IO.puts("Found a block")
    # Ignore the call if current block chain is not exactly
    # equal to the blockchain with miner. Could happen if the
    # node failed to kill miner after receiving a longer chain.
    updated_state =
      if CryptoCoin.Blockchain.is_equal(blockchain, state.block_chain) == true do
        chain = CryptoCoin.Blockchain.add(block, blockchain)

        transaction_units_map =
          update_transaction_units_map_for_transactions(transactions, state.trasaction_units_map)

        state = state |> Map.put(:trasaction_units_map, transaction_units_map)

        transaction = transactions |> Enum.at(0)
        # Remove the transaction from processing map
        transaction_hash = CryptoCoin.Utils.hash(CryptoCoin.Utils.encode(transaction))
        processing_transactions = state.processing_transactions |> Map.delete(transaction_hash)
        state = state |> Map.put(:processing_transactions, processing_transactions)

        # Notify other nodes and wallets that we found a new longer chain.
        notify_block_chain(chain, state)
        state |> Map.put(:block_chain, chain)
      else
        state
      end

    {:noreply, updated_state}
  end

  # Notify both wallets and peers from topology.
  defp notify_block_chain(chain, state) do
    wallets = state |> Map.get(:wallets)
    topology = state |> Map.get(:topology)

    peers =
      if topology != nil do
        CryptoCoin.FullNetworkTopology.all_neighbours_for_node(topology, self())
      else
        []
      end

    notify_block_chain_to_peers(chain, wallets ++ peers)
  end

  defp notify_block_chain_to_peers(chain, peers) do
    if CryptoCoin.Blockchain.chain_length(chain) != 0 do
      Enum.each(peers, fn pid ->
        send(pid, {:handle_blockchain_broadcast, chain, self()})
      end)
    else
    end
  end

  # Notify peers from topology about the transaction
  defp notify_transaction(transaction, state) do
    topology = state |> Map.get(:topology)

    peers =
      if topology != nil do
        CryptoCoin.FullNetworkTopology.all_neighbours_for_node(topology, self())
      else
        []
      end

    Enum.each(peers, fn pid ->
      send(pid, {:confirm_trasaction, transaction})
    end)
  end
end
