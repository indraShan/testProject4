defmodule CryptoCoin.Wallet do
  def create(public_key, private_key) do
    GenServer.start_link(
      __MODULE__,
      [public_key: public_key, private_key: private_key],
      []
    )
  end

  def init(opts) do
    state = %{
      public_key: opts[:public_key],
      private_key: opts[:private_key],
      block_chain: nil,
      unspent_transactions: []
    }

    {:ok, state}
  end

  def handle_blockchain_broadcast(pid, chain) do
    send(pid, {:handle_blockchain_broadcast, chain})
  end

  def get_balance(pid, caller) do
    # IO.puts("get_balance called")
    GenServer.cast(pid, {:get_balance, caller})
  end

  # Private methods
  def handle_info({:handle_blockchain_broadcast, chain}, state) do
    # For now go through the entire blockchain.
    # May be there is a better way.
    state = state |> Map.put(:block_chain, chain)

    unspent_transactions = unspent_transactions(state.public_key, state.private_key, chain)
    state = state |> Map.put(:unspent_transactions, unspent_transactions)

    {:noreply, state}
  end

  def handle_cast({:get_balance, caller}, state) do
    send(caller, {:current_balance, availableBalance(state.unspent_transactions)})
    {:noreply, state}
  end

  defp availableBalance(utxos) do
    Enum.reduce(utxos, 0, fn utxo, amount ->
      amount + CryptoCoin.TransactionUnit.get_amount(utxo)
    end)
  end

  defp unspent_transactions(public_key, private_key, chain) do
    if chain != nil do
      CryptoCoin.Blockchain.unspent_transactions(public_key, private_key, chain)
    else
      []
    end
  end
end
