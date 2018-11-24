defmodule BlockTest do
  use ExUnit.Case

  test "create block" do
    block = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    assert block != nil
  end

  test "verify_block_parent" do
    first = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    second = CryptoCoin.Block.create("second_block", first, 2, nil, 3)
    assert CryptoCoin.Block.verify_block_parent(second, first) == true

    third = CryptoCoin.Block.create("third_block", first, 2, nil, 3)
    assert CryptoCoin.Block.verify_block_parent(third, second) == false
  end

  test "verify get transactions" do
    transaction = TestUtils.create_valid_transaction()
    block = CryptoCoin.Block.create("first_block", nil, 2, [transaction], 3)

    assert length(CryptoCoin.Block.get_trasactions(block)) == 1
  end
end
