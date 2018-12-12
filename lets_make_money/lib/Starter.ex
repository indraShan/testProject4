defmodule Starter do
  # mix run -e Starter
  def start(_type, _args) do
    {:ok, app} = CryptoCoin.Simulator.start_link(self())
    waitForResult()
    {:ok, app}
    # Task.start(fn -> nil end)
  end

  def waitForResult() do
    receive do
      {:terminate} ->
        nil
        # IO.puts("Done")
    end
  end
end
