defmodule CryptoCoin.Simulator do
  use GenServer
  @mining_reward 20
  @genesis_reward 500
  @diff_level 1
  @number_of_nodes 100
  @number_of_wallets 60
  @max_number_of_transactions 100
  @transaction_wait_interval 1

  def start_link(_opts) do
    GenServer.start_link(
      __MODULE__,
      [],
      []
    )
  end

  def get_simulator_stats(pid) do
    GenServer.cast(pid, {:get_simulator_stats})
  end

  def handle_cast({:get_simulator_stats}, state) do
    {:noreply, state}
  end

  def init(opts) do
    state = %{
      nodes: [],
      wallets: [],
      # wallet_public_key -> {walletid, pub_key, amount}
      wallets_amount_map: %{},
      wallets_public_keys: [],
      number_of_transactions: 0,
      positive_balance_accounts: %{}
    }

    send(self(), {:create_network})

    {:ok, state}
  end

  defp create_node(public_key, private_key, mining_reward, difficulty_level) do
    {:ok, node} =
      CryptoCoin.FullNode.start(
        CryptoCoin.Blockchain.create(),
        public_key,
        private_key,
        mining_reward,
        difficulty_level
      )

    node
  end

  defp create_full_nodes(state) do
    Enum.reduce(1..@number_of_nodes, state, fn index, state_map ->
      pub_data =
        "public_key" <>
          Integer.to_string(index) <> NaiveDateTime.to_string(NaiveDateTime.utc_now())

      private_data =
        "priv_key" <> Integer.to_string(index) <> NaiveDateTime.to_string(NaiveDateTime.utc_now())

      public_key = CryptoCoin.Utils.hash(pub_data)
      private_key = CryptoCoin.Utils.hash(private_data)

      node =
        create_node(
          public_key,
          public_key,
          @mining_reward,
          @diff_level
        )

      {:ok, wallet} = CryptoCoin.Wallet.create(public_key, public_key)
      CryptoCoin.Wallet.connected_with_full_node(wallet, node)
      nodes = state_map |> Map.get(:nodes)
      nodes = [node] ++ nodes
      wallets = state_map |> Map.get(:wallets)
      wallets = [wallet] ++ wallets
      state_map = state_map |> Map.put(:nodes, nodes)
      state_map |> Map.put(:wallets, wallets)
    end)
  end

  defp create_wallets() do
    if @number_of_wallets > 0 do
      Enum.reduce(1..@number_of_wallets, [], fn index, wallets ->
        pub_data =
          "public_key" <>
            Integer.to_string(index) <> NaiveDateTime.to_string(NaiveDateTime.utc_now())

        private_data =
          "priv_key" <>
            Integer.to_string(index) <> NaiveDateTime.to_string(NaiveDateTime.utc_now())

        public_key = CryptoCoin.Utils.hash(pub_data)
        private_key = CryptoCoin.Utils.hash(private_data)

        {:ok, wallet} =
          CryptoCoin.Wallet.create(
            public_key,
            public_key
          )

        [wallet] ++ wallets
      end)
    else
      []
    end
  end

  def handle_info({:wallet_state_change, wallet, public_key, chain, balance}, state) do
    wallets_amount_map = state.wallets_amount_map
    # Update balance
    wallets_amount_map = wallets_amount_map |> Map.put(public_key, {wallet, public_key, balance})
    updated_state = state |> Map.put(:wallets_amount_map, wallets_amount_map)
    # IO.inspect(wallets_amount_map)
    # IO.inspect(updated_state |> Map.get(:genesis_wallet))
    wallets_public_keys = updated_state |> Map.get(:wallets_public_keys)
    all_keys = Map.keys(wallets_amount_map)

    updated_state =
      if balance > 0 and
           updated_state.positive_balance_accounts |> Map.has_key?(public_key) == false do
        positive_balance_accounts = updated_state.positive_balance_accounts |> Map.put(public_key, wallet)
        updated_state |> Map.put(:positive_balance_accounts, positive_balance_accounts)
      else
        updated_state
      end

    updated_state =
      if balance <= 0 and
           updated_state.positive_balance_accounts |> Map.has_key?(public_key) == true do
        positive_balance_accounts = updated_state.positive_balance_accounts |> Map.delete(public_key)
        updated_state |> Map.put(:positive_balance_accounts, positive_balance_accounts)
      else
        updated_state
      end

    # Update the wallets_public keys to reflect all known wallets.
    updated_state =
      if length(wallets_public_keys) != length(all_keys) do
        wallets_public_keys =
          Enum.reduce(all_keys, [], fn key, acc ->
            [key] ++ acc
          end)

        updated_state |> Map.put(:wallets_public_keys, wallets_public_keys)
      else
        updated_state
      end

    recorded_keys_count = updated_state |> Map.get(:wallets_public_keys) |> length
    # Are we in a stable state?
    updated_state =
      if recorded_keys_count == length(all_keys) do
        transaction_count = updated_state.number_of_transactions
        # IO.puts("transaction_count = " <> Integer.to_string(transaction_count))
        chain_length = CryptoCoin.Blockchain.chain_length(chain)
        IO.puts("chain_length = " <> Integer.to_string(chain_length))

        if transaction_count == 0 do
          # Mine genesis block
          CryptoCoin.FullNode.mine_genesis(updated_state.genesis_node, @genesis_reward)
          updated_state |> Map.put(:number_of_transactions, 1)
        else
          if chain_length > @max_number_of_transactions do
            # We are done. Notify caller.
            IO.puts("Done")
            # IO.inspect(updated_state.wallets_amount_map)
            updated_state
          else
            # From the positive balance accounts, choose a any count
            # Choose a random receiver.
            if updated_state.positive_balance_accounts |> Map.keys() |> length > 0 do
              # Get a random receiver other than the sender.
              all_positive_accounts = updated_state.positive_balance_accounts |> Map.keys()
              index1 = Enum.random(0..(length(all_positive_accounts) - 1))
              index2 = Enum.random(0..(length(all_positive_accounts) - 1))

              sender1_key = all_positive_accounts |> Enum.at(index1)
              sender2_key = all_positive_accounts |> Enum.at(index2)

              {wallet1, public_key1, balance1} =
                updated_state.wallets_amount_map |> Map.get(sender1_key)

              {wallet2, public_key2, balance2} = updated_state.wallets_amount_map |> Map.get(sender2_key)

              total_send = balance1 * 0.5
              receiver_key = receiver_key_for_sender(public_key1, updated_state)
              transact(wallet1, receiver_key, total_send * 0.5)
              receiver_key = receiver_key_for_sender(public_key1, updated_state)
              transact(wallet1, receiver_key, total_send * 0.5)

              total_send = balance2 * 0.5
              receiver_key = receiver_key_for_sender(public_key2, updated_state)
              transact(wallet2, receiver_key, total_send * 0.5)
              receiver_key = receiver_key_for_sender(public_key2, updated_state)
              transact(wallet2, receiver_key, total_send * 0.5)

              # Increase transaction_count by one
              updated_state |> Map.put(:number_of_transactions, transaction_count + 6)
            else
              # No changes to the state.
              updated_state
            end
          end
        end
      else
        # We are still building the keys.
        updated_state
      end

    {:noreply, updated_state}
  end

  defp receiver_key_for_sender(sender_key, state) do
    keys = state |> Map.get(:wallets_public_keys)
    index = Enum.random(0..(length(keys) - 1))
    receiver_key = keys |> Enum.at(index)

    if receiver_key == sender_key do
      receiver_key_for_sender(sender_key, state)
    else
      receiver_key
    end
  end

  def handle_info({:make_a_transaction, sender, receiver_key, amount}, state) do
    CryptoCoin.Wallet.send_money(sender, receiver_key, amount)
    {:noreply, state}
  end

  defp transact(sender, receiver_key, amount) do
    # Process.send_after(self(), {:make_a_transaction, sender, receiver_key, amount}, 100)
    CryptoCoin.Wallet.send_money(sender, receiver_key, amount)
  end

  defp wallet_to_transact(state) do
    wallets_public_keys = state |> Map.get(:wallets_public_keys)

    if length(wallets_public_keys) > 1 do
      sender_index = Enum.random(0..(length(wallets_public_keys) - 1))
      sender_key = wallets_public_keys |> Enum.at(sender_index)
      {sender_wallet, _, sender_balance} = state.wallets_amount_map |> Map.get(sender_key)

      reeiver_index = Enum.random(0..(length(wallets_public_keys) - 1))
      receiver_key = wallets_public_keys |> Enum.at(reeiver_index)
      {_, receiver_key, _} = state.wallets_amount_map |> Map.get(receiver_key)

      if sender_balance <= 0 || sender_key == receiver_key do
        {nil, nil, 0}
      else
        {sender_wallet, receiver_key, sender_balance * 0.5}
      end
    else
      {nil, nil, 0}
    end
  end

  def handle_info({:create_network}, state) do
    # Create nodes along with their wallets.
    updated_state = create_full_nodes(state)

    # Then create some more wallets. These wallets must be connected
    # with a random node
    wallets = create_wallets()
    nodes = updated_state |> Map.get(:nodes)
    nodes_count = nodes |> length

    Enum.each(wallets, fn wallet ->
      index = Enum.random(0..(nodes_count - 1))
      node = Enum.at(nodes, index)
      CryptoCoin.Wallet.connected_with_full_node(wallet, node)
    end)

    existing_wallets = updated_state |> Map.get(:wallets)
    updated_state = updated_state |> Map.put(:wallets, existing_wallets ++ wallets)

    # Create a topology
    topology = CryptoCoin.FullNetworkTopology.create_structure(nodes)
    # Let the node know which topology it belongs to
    # For now all belong to same topology
    Enum.each(nodes, fn node ->
      CryptoCoin.FullNode.set_topology(node, topology)
    end)

    # Wallets should notify this class when their ballance changes.
    wallets = updated_state |> Map.get(:wallets)

    Enum.each(wallets, fn wallet ->
      CryptoCoin.Wallet.set_state_change_listener(wallet, self())
    end)

    # Choose a node to mine genesis block
    updated_state = updated_state |> Map.put(:genesis_node, nodes |> Enum.at(0))

    # IO.puts(updated_state |> Map.get(:nodes) |> length)
    # updated_state = updated_state |> Map.put(:genesis_wallet, wallets |> Enum.at(0))
    # updated_state = updated_state |> Map.put(:receiver_key, public_key)

    {:noreply, updated_state}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end
end
