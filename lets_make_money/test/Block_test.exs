defmodule BlockTest do
  use ExUnit.Case

  test "create block" do
    block = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    assert block != nil
  end

  test "verify get_nonce" do
    block = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    assert CryptoCoin.Block.get_nonce(block) == 2
  end

  test "verify_block_parent" do
    first = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    second = CryptoCoin.Block.create("second_block", first, 2, nil, 3)
    assert CryptoCoin.Block.verify_block_parent(second, first) == true

    third = CryptoCoin.Block.create("third_block", first, 2, nil, 3)
    assert CryptoCoin.Block.verify_block_parent(third, second) == false
  end

  test "verify is_valid" do
    block = TestUtils.create_valid_block()
    assert CryptoCoin.Block.is_valid(block) == true
  end

  test "verify is_older_than" do
    block1 = TestUtils.create_valid_block()
    block2 = TestUtils.create_valid_block2()
    assert CryptoCoin.Block.is_older_than(block1, block2) == true
    assert CryptoCoin.Block.is_older_than(block2, block1) == false
  end

  test "verify is_equal" do
    block1 = TestUtils.create_valid_block()
    block2 = TestUtils.create_valid_block()
    assert CryptoCoin.Block.is_equal(block2, block1) == true

    block3 = TestUtils.create_valid_block2()
    assert CryptoCoin.Block.is_equal(block3, block1) == false
  end

  test "verify get transactions" do
    chain = TestUtils.create_valid_blockchain1()
    block = CryptoCoin.Blockchain.get_last_block(chain)

    assert length(CryptoCoin.Block.get_trasactions(block)) == 1
    assert CryptoCoin.Block.is_valid(block) == true
  end
end
