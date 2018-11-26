defmodule CryptoCoin.Transaction do
  def create(inputs, outputs) do
    %{"inputs" => inputs, "outputs" => outputs}
  end

  def get_inputs(transaction) do
    transaction |> Map.get("inputs")
  end

  def get_outputs(transaction) do
    transaction |> Map.get("outputs")
  end

  def get_inputs(transaction, public_key) do
    inputs = transaction |> Map.get("inputs")

    Enum.filter(inputs, fn input ->
      CryptoCoin.TransactionUnit.is_owned_by(input, public_key)
    end)
  end

  def is_valid(transaction) do
    inputs = CryptoCoin.Transaction.get_inputs(transaction)
    outputs = CryptoCoin.Transaction.get_outputs(transaction)

    input_val = Enum.reduce(inputs, 0, fn x, acc -> x + acc end)
    output_val = Enum.reduce(outputs, 0, fn x, acc -> x + acc end)
    if input_val >= output_val do
      true
    else
      false
    end
  end

  # Returns outputs where the private key can be used to unlock
  # the unit
  def get_outputs(transaction, private_key) do
    outputs = transaction |> Map.get("outputs")

    Enum.filter(outputs, fn output ->
      CryptoCoin.TransactionUnit.is_owned_by(output, private_key)
    end)
  end
end
