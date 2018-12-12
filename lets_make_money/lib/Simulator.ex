defmodule CryptoCoin.Simulator do
  use GenServer
  @mining_reward 10
  @genesis_reward 500
  @diff_level 3
  @number_of_nodes 3
  @number_of_wallets 3
  @max_number_of_transactions 5
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
    # {:ok, {priv, pub}} = RsaEx.generate_keypair()
    # # First node
    # first_node = create_node(pub, priv, @mining_reward, @diff_level)
    # # Mine genesis block
    # CryptoCoin.FullNode.mine_genesis(first_node)
    # # Create wallet for this miner
    # {:ok, first_wallet} = CryptoCoin.Wallet.create(pub, priv)
    # CryptoCoin.Wallet.connected_with_full_node(first_wallet, first_node)

    state = %{
      nodes: [],
      wallets: [],
      # wallet_public_key -> {walletid, pub_key, amount}
      wallets_amount_map: %{},
      wallets_public_keys: [],
      number_of_transactions: 0
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
      _private_key = CryptoCoin.Utils.hash(private_data)

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

        # {:ok, {priv, pub}} = RsaEx.generate_keypair()
        public_key = CryptoCoin.Utils.hash(pub_data)
        _private_key = CryptoCoin.Utils.hash(private_data)

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

  def handle_info({:wallet_state_change, wallet, public_key, _chain, balance}, state) do
    wallets_amount_map = state.wallets_amount_map
    # Update balance
    wallets_amount_map = wallets_amount_map |> Map.put(public_key, {wallet, public_key, balance})
    updated_state = state |> Map.put(:wallets_amount_map, wallets_amount_map)
    # IO.inspect(wallets_amount_map)
    # IO.inspect(updated_state |> Map.get(:genesis_wallet))
    wallets_public_keys = updated_state |> Map.get(:wallets_public_keys)
    all_keys = Map.keys(wallets_amount_map)

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
        # IO.puts(transaction_count)

        if transaction_count == 0 do
          # Mine genesis block
          # IO.puts("Mining genesis")
          CryptoCoin.FullNode.mine_genesis(updated_state.genesis_node, @genesis_reward)
          updated_state |> Map.put(:number_of_transactions, 1)
        else
          if transaction_count >= @max_number_of_transactions do
            updated_state
          else
            # Schedule next step of transactions.
            genesis_wallet = updated_state.genesis_wallet

            if genesis_wallet == wallet do
              # IO.puts("Next transaction")
              # 4 transactions.
              half = balance * 0.5
              first = half * 0.25
              second = half * 0.25
              third = half * 0.25
              fourth = half * 0.25
              transact(genesis_wallet, updated_state.receiver_key, first)
              transact(genesis_wallet, updated_state.receiver_key, second)
              transact(genesis_wallet, updated_state.receiver_key, third)
              transact(genesis_wallet, updated_state.receiver_key, fourth)
              updated_state |> Map.put(:number_of_transactions, transaction_count + 1)
            else
              updated_state
            end
          end
        end
      else
        updated_state
      end

    {:noreply, updated_state}
  end

  defp transact(sender, receiver_key, amount) do
    # IO.puts("sending")
    # IO.puts(amount)
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

  def handle_info({:make_a_transaction}, state) do
    transaction_count = state.number_of_transactions
    # IO.puts(transaction_count)

    updated_state =
      if transaction_count < @max_number_of_transactions do
        {sender, receiver_key, amount} = wallet_to_transact(state)
        # If we can't find a wallet to do a transaction, schedule again.
        if sender != nil do
          transact(sender, receiver_key, amount)
          schedule_transaction(@transaction_wait_interval)
          state |> Map.put(:number_of_transactions, transaction_count + 1)
        else
          schedule_transaction(0)
          state
        end
      else
        # We do not schedule a transaction as we have reached the count.
        state
      end

    {:noreply, updated_state}
  end

  def handle_info({:create_network}, state) do
    # Create nodes along with their wallets.
    updated_state = create_full_nodes(state)

    # Then create some more wallets. These wallets must be connected
    # with a random node
    wallets = create_wallets()
    nodes = updated_state |> Map.get(:nodes)
    nodes_count = nodes |> length

    pub_data =
      "public_key" <> Integer.to_string(56) <> NaiveDateTime.to_string(NaiveDateTime.utc_now())

    private_data =
      "priv_key" <> Integer.to_string(56) <> NaiveDateTime.to_string(NaiveDateTime.utc_now())

    # {:ok, {priv, pub}} = RsaEx.generate_keypair()
    public_key = CryptoCoin.Utils.hash(pub_data)
    _private_key = CryptoCoin.Utils.hash(private_data)

    {:ok, fake_wallet} =
      CryptoCoin.Wallet.create(
        public_key,
        public_key
      )

    wallets = [fake_wallet] ++ wallets

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

    # IO.puts(updated_state |> Map.get(:wallets) |> length)
    # IO.puts(updated_state |> Map.get(:nodes) |> length)

    # Choose a node to mine genesis block
    updated_state = updated_state |> Map.put(:genesis_node, nodes |> Enum.at(0))

    updated_state = updated_state |> Map.put(:genesis_wallet, wallets |> Enum.at(0))
    updated_state = updated_state |> Map.put(:receiver_key, public_key)

    {:noreply, updated_state}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  defp schedule_transaction(delay) do
    Process.send_after(self(), {:make_a_transaction}, delay)
  end
end
