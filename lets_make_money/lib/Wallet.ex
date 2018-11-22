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
    IO.puts("get_balance called")
    GenServer.cast(pid, {:get_balance, caller})
  end

  # Private methods
  def handle_cast({:handle_blockchain_broadcast, chain}, state) do
    {:noreply, state |> Map.put(:block_chain, chain)}
  end

  def handle_cast({:get_balance, caller}, state) do
    IO.puts("get_balance received")
    send(caller, {:current_balance, 30})
    {:noreply, state}
  end
end
