defmodule CryptoCoin.Utils do
  def hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16()
  end

  def prefixStringForDifficultyLevel(diff) do
    Enum.reduce(1..diff, "", fn _, acc ->
      Integer.to_string(0) <> acc
    end)
  end

  def encode(data) do
    Poison.encode!(data)
  end
end
