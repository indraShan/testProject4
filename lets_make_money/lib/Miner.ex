defmodule CryptoCoin.Miner do
  def start(node) do
    Task.start(fn -> wait(node) end)
  end

  defp wait(node) do
    receive do
      {:mine} ->
        wait(node)

      {:stop} ->
        IO.puts("Miner done")
    end
  end
end
