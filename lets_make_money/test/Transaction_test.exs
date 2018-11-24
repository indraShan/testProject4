defmodule TransactionTest do
  use ExUnit.Case

  test "transaction creation" do
    assert TestUtils.create_valid_transaction() != nil
  end

  test "inputs and output get" do
    transaction = TestUtils.create_valid_transaction()

    inputs = CryptoCoin.Transaction.get_inputs(transaction)
    assert length(inputs) == 2

    outputs = CryptoCoin.Transaction.get_outputs(transaction)
    assert length(outputs) == 3
  end

  test "owned outputs" do
    transaction = TestUtils.create_valid_transaction()
    owned_outputs = CryptoCoin.Transaction.get_outputs(transaction, "key1")
    assert length(owned_outputs) == 1
  end

  # Verify that it is a valid transaction
end
