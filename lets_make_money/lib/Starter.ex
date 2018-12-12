defmodule Starter do
  # mix run -e Starter
  def start(_type, _args) do
    {:ok, app} = CryptoCoin.Simulator.start_link(self())
    CryptoCoin.Simulator.set_state_change_listener(app, self())
    waitForResult()
    {:ok, app}
    # Task.start(fn -> nil end)
  end

  def waitForResult() do
    receive do
      {:network_state, chain_length, number_of_nodes, number_of_wallets, wallets_amount_map,
         block_chain_length_time_map, block_chain_length_nounce_value_map} ->
           IO.puts("Received network state = " <> Integer.to_string(chain_length))
        # IO.puts("Done")
    end
  end
end
