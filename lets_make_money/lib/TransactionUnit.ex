defmodule CryptoCoin.TransactionUnit do
  def create(unlock_key, amount, unique_id) do
    # transaction id
    # signature
    %{"unlock_key" => unlock_key, "amount" => amount, "unique_id" => unique_id}
  end

  def get_unique_id(output) do
    output |> Map.get("unique_id")
  end


  def get_amount(unit) do
    unit |> Map.get("amount")
  end

  # returns true if the unit is owned by the private_key passed.
  def is_owned_by(output, private_key) do
    output |> Map.get("unlock_key") == private_key
  end
end
