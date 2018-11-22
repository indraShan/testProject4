defmodule CryptoCoin.Transaction do
  def create(from, to, amount) do
    %{"from" => from, "to" => to, "amount" => amount}
  end
end
