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

  # Private methods
  def generate_outputs(sender, recepient, inputs, amount) do
    if(length(inputs) > 0) do
      {recepient_utxos, total} =
        Enum.flat_map_reduce(inputs, 0, fn x, acc ->
          if CryptoCoin.TransactionUnit.get_amount(x) + acc <= amount do
            {[x], CryptoCoin.TransactionUnit.get_amount(x) + acc}
          else
            {:halt, acc}
          end
        end)

      sender_utxos = inputs -- recepient_utxos

      sender_money = Enum.map(sender_utxos, fn x -> CryptoCoin.TransactionUnit.get_amount(x) end)

      recepient_money =
        Enum.map(recepient_utxos, fn x -> CryptoCoin.TransactionUnit.get_amount(x) end)

      # IO.inspect sender_money
      # IO.inspect recepient_money
      # IO.puts "#{total}"

      # if sender_money is empty list, following condition should never ideally be true
      if(total < amount) do
        val = Enum.at(sender_money, 0)
        break_val = amount - total
        adjust_val = val - break_val
        # IO.puts "#{break_val}"
        # IO.puts "#{adjust_val} ********************"

        recepient_money = recepient_money ++ [break_val]
        sender_money = List.delete_at(sender_money, 0)
        sender_money = [adjust_val] ++ sender_money
        # IO.inspect sender_money
        # IO.inspect recepient_money
        %{recepient => recepient_money, sender => sender_money}
      else
        %{recepient => recepient_money, sender => [0] ++ sender_money}
      end
    else
      %{}
    end
  end

  def send_money_validate(amount, utxos) do
    if(length(utxos) > 0) do
      # sort utxos in ascending order
      valid_utxos =
        Enum.sort(
          utxos,
          &(CryptoCoin.TransactionUnit.get_amount(&1) <= CryptoCoin.TransactionUnit.get_amount(&2))
        )

      # [last] = Enum.take(valid_utxos, -1)
      last_element = List.last(valid_utxos)

      # if largest element's amount equals amount to be sent, no need to iterate
      if CryptoCoin.TransactionUnit.get_amount(last_element) == amount do
        [last_element]

        # else, iterate over list by accumulating transaction values 
      else
        {utx_list, total} =
          Enum.flat_map_reduce(valid_utxos, 0, fn x, acc ->
            if CryptoCoin.TransactionUnit.get_amount(x) + acc <= amount do
              {[x], CryptoCoin.TransactionUnit.get_amount(x) + acc}
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
    if chain != nil do
      CryptoCoin.Blockchain.unspent_transactions(public_key, private_key, chain)
    else
      []
    end
  end
end
