defmodule CryptoCoin.Transaction do
  def create(inputs, outputs) do
    %{"inputs" => inputs, "outputs" => outputs}
  end

  def create() do
    %{"timestamp" => NaiveDateTime.utc_now(), "inputs" => [], "outputs" => []}
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
    outputs = [output] ++ outputs
    transaction |> Map.put("outputs", outputs)
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

  # TODO: Assumes that the transaction is already unlocked
  def is_valid(transaction) do
    inputs = CryptoCoin.Transaction.get_inputs(transaction)
    outputs = CryptoCoin.Transaction.get_outputs(transaction)

    input_val =
      Enum.reduce(inputs, 0, fn x, acc -> CryptoCoin.TransactionUnit.get_amount(x) + acc end)

    output_val =
      Enum.reduce(outputs, 0, fn x, acc -> CryptoCoin.TransactionUnit.get_amount(x) + acc end)

    inputs_check =
      Enum.filter(inputs, fn x ->
        CryptoCoin.TransactionUnit.get_unique_id(x) != nil and
          CryptoCoin.TransactionUnit.get_amount(x) >= 0
      end)

    outputs_check =
      Enum.filter(outputs, fn x ->
        CryptoCoin.TransactionUnit.get_unique_id(x) != nil and
          CryptoCoin.TransactionUnit.get_amount(x) >= 0
      end)

    id_amount_valid =
      if(length(inputs_check) == length(inputs) and length(outputs_check) == length(outputs)) do
        true
      else
        false
      end

    if input_val >= output_val and id_amount_valid == true do
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
