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
      unspent_transactions: [],
      full_node: nil,
      state_change_listener: nil,
      # List of tuples {receiver_key, amount}
      pending_transactions: [],
      in_flight_transaction: nil
    }

    {:ok, state}
  end

  # Only to make testing easier.
  def handle_blockchain_broadcast(pid, chain, caller) do
    send(pid, {:handle_blockchain_broadcast, chain, caller})
  end

  def connected_with_full_node(pid, node) do
    GenServer.cast(pid, {:connected_with_full_node, node})
  end

  def set_state_change_listener(pid, listener) do
    GenServer.cast(pid, {:set_state_change_listener, listener})
  end

  def get_balance(pid, caller) do
    # IO.puts("get_balance called")
    GenServer.cast(pid, {:get_balance, caller})
  end

  def send_money(pid, receiver_key, amount) do
    GenServer.cast(pid, {:send_money, receiver_key, amount})
  end

  def handle_info({:handle_blockchain_broadcast, chain, _}, state) do
    # For now go through the entire blockchain.
    # May be there is a better way.
    state = state |> Map.put(:block_chain, chain)

    unspent_transactions = unspent_transactions(state.public_key, state.private_key, chain)
    state = state |> Map.put(:unspent_transactions, unspent_transactions)

    # Set in-flight transaction to nil as we just proccesed it.
    state = state |> Map.put(:in_flight_transaction, nil)

    # Wallets balance might have changed.
    # Send a state change notification to whoever is intested.
    notify_state_change(state, state.state_change_listener)

    # If we have pending transactions, lets send one of them now.
    pending_transactions =
      if state.pending_transactions |> length > 0 do
        {{receiver_key, amount}, pending_transactions} =
          state.pending_transactions |> List.pop_at(0)

        CryptoCoin.Wallet.send_money(self(), receiver_key, amount)
        pending_transactions
      else
        []
      end

    state = state |> Map.put(:pending_transactions, pending_transactions)

    {:noreply, state}
  end

  def handle_cast({:connected_with_full_node, node}, state) do
    # Ask the node to send callbacks.
    # IO.puts("connecting with full node")
    CryptoCoin.FullNode.add_wallet(node, self())
    {:noreply, state |> Map.put(:full_node, node)}
  end

  def handle_cast({:set_state_change_listener, listener}, state) do
    notify_state_change(state, listener)
    {:noreply, state |> Map.put(:state_change_listener, listener)}
  end

  defp notify_state_change(state, listener) do
    if listener != nil do
      send(
        listener,
        {:wallet_state_change, self(), state.public_key, state.block_chain,
         availableBalance(state.unspent_transactions)}
      )
    end
  end

  def handle_info({:confirm_trasaction, _transaction}, state) do
    {:noreply, state}
  end

  def handle_cast({:send_money, receiver_key, amount}, state) do
    updated_state =
      if state.in_flight_transaction == nil do
        available_inputs = send_money_validate(amount, state.unspent_transactions)
        # TODO: invalid input
        if length(available_inputs) != 0 do
          outputs_map = generate_outputs(state.public_key, receiver_key, available_inputs, amount)

          # outputs =
          # (outputs_map |> Map.get(state.public_key)) ++ (outputs_map |> Map.get(receiver_key))
          transaction = create_transaction(available_inputs, outputs_map)

          send_transaction(transaction, state)

          state |> Map.put(:in_flight_transaction, transaction)
        else
          state
        end
      else
        # We have an existing in flight transaction.
        # Just add the new transactions to pending list, they would be processed
        # when the current transaction is confimed.
        pending_transactions = state.pending_transactions
        pending_transactions = [{receiver_key, amount}] ++ pending_transactions
        state |> Map.put(:pending_transactions, pending_transactions)
      end

    {:noreply, updated_state}
  end

  defp send_transaction(transaction, state) do
    if state.full_node != nil && CryptoCoin.Transaction.is_valid(transaction) == true do
      CryptoCoin.FullNode.confirm_trasaction(state.full_node, transaction)
    end
  end

  defp create_transaction(inputs, outputs_map) do
    transaction = CryptoCoin.Transaction.create()
    transaction = CryptoCoin.Transaction.add_inputs(transaction, inputs)

    Enum.reduce(outputs_map |> Map.keys(), transaction, fn key, acc_trans ->
      outputs = outputs_map |> Map.get(key)

      Enum.reduce(outputs, acc_trans, fn output, edit_trans ->
        CryptoCoin.Transaction.add_transaction_output(
          edit_trans,
          key,
          output
        )
      end)
    end)
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
