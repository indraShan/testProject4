defmodule CryptoCoin.Transaction do
  def create(inputs, outputs) do
    %{"inputs" => inputs, "outputs" => outputs}
  end

  def create() do
    %{"timestamp" => :os.system_time(:millisecond), "inputs" => [], "outputs" => []}
  end

  def add_inputs(transaction, inputs) do
    inputs = inputs ++ get_inputs(transaction)
    transaction |> Map.put("inputs", inputs)
  end

  def add_outputs(transaction, outputs) do
    outputs = outputs ++ get_outputs(transaction)
    transaction |> Map.put("outputs", outputs)
  end

  def add_transaction_output(transaction, key, amount) do
    outputs = get_outputs(transaction)
    output_data = CryptoCoin.Utils.encode(transaction) <> Integer.to_string(length(outputs))
    output_id = CryptoCoin.Utils.hash(output_data)
    output = CryptoCoin.TransactionUnit.create(key, amount, output_id)
    outputs = outputs ++ [output]
    add_outputs(transaction, outputs)
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

  def is_valid(_trasaction) do
    true
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
