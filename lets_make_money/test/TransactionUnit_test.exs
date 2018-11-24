defmodule TransactionUnitTest do
  use ExUnit.Case

  test "unit creation" do
    unit = CryptoCoin.TransactionUnit.create("key", 10, "id:1")
    assert unit != nil
  end

  test "get amount" do
    unit = CryptoCoin.TransactionUnit.create("key", 10, "id:1")
    assert CryptoCoin.TransactionUnit.get_amount(unit) == 10
  end

  test "get unique id" do
    unit = CryptoCoin.TransactionUnit.create("key", 10, "id:1")
    assert CryptoCoin.TransactionUnit.get_unique_id(unit) == "id:1"
    assert CryptoCoin.TransactionUnit.get_unique_id(unit) != "id:2"
  end

  test "is_owned_by" do
    unit = CryptoCoin.TransactionUnit.create("key1", 10, "id:1")

    assert CryptoCoin.TransactionUnit.is_owned_by(unit, "key1") == true
    assert CryptoCoin.TransactionUnit.is_owned_by(unit, "key2") == false
  end

  # Verify that unlocking works only if the right user does it.
end
