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
      block_chain: nil
    }

    {:ok, state}
  end

  def handle_blockchain_broadcast(pid, chain) do
    GenServer.cast(pid, {:handle_blockchain_broadcast, chain})
  end

  def get_balance(pid, caller) do
    # IO.puts("get_balance called")
    GenServer.cast(pid, {:get_balance, caller})
  end

  def send_money_validate(pid, recepient, amount,  caller) do
    GenServer.cast(pid, {:send_money_validate, recepient, amount, caller})
  end

  # Private methods
  def handle_cast({:handle_blockchain_broadcast, chain}, state) do
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

  def handle_cast({:send_money_validate, recepient, amount, caller}, state) do
    utxos = state.unspent_transactions
    inputs = check_send_money_valid(amount, utxos)
    inputs = 
    Enum.map(inputs, fn x -> Map.get(x, "amount") end)

    send(caller, {:send_money_valid, inputs})
    {:noreply, state}
  end

  defp check_send_money_valid(amount, utxos) do
    if(length(utxos)>0) do
      valid_utxos = Enum.sort(utxos, &(Map.get(&1, "amount") <= Map.get(&2, "amount")))
      # IO.inspect valid_utxos
      [last] = Enum.take(valid_utxos, -1)

      if Map.get(last, "amount") == amount do
        [last]
      else
        {utx_list, total} = 
        Enum.flat_map_reduce(valid_utxos, 0, fn x, acc ->
          if Map.get(x, "amount") + acc < amount do
            {[x], Map.get(x, "amount") + acc}
          else
            {:halt, acc}
          end
        end)

        # IO.inspect utx_list
        list_size = length(utx_list)
        if total < amount do
          if length(valid_utxos) > list_size do
            utx_list ++ [Enum.at(valid_utxos, list_size)]
          else
            []
          end

        # else condition will only be executed when total == amount
        # total > amount should never be encountered 
        else
          utx_list
        end
      end
    else
      []
    end
  end

  defp availableBalance(utxos) do
    Enum.reduce(utxos, 0, fn utxo, amount ->
      amount + CryptoCoin.TransactionUnit.get_amount(utxo)
    end)
  end

  defp unspent_transactions(public_key, private_key, chain) do
    CryptoCoin.Blockchain.unspent_transactions(public_key, private_key, chain)
  end
end
