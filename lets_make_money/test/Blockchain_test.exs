defmodule BlockchainTest do
  use ExUnit.Case

  test "block chain creation" do
    block = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    chain = CryptoCoin.Blockchain.create(block)
    assert chain != nil
  end

  test "block chain add and last block" do
    block = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)

    chain = CryptoCoin.Blockchain.create(block)
    assert CryptoCoin.Blockchain.get_last_block(chain) == block

    second = CryptoCoin.Block.create("second_block", block, 2, nil, 3)
    chain = CryptoCoin.Blockchain.add(second, chain)

    assert CryptoCoin.Blockchain.get_last_block(chain) == second
  end

  test "blockchain is valid" do
    first = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    chain = CryptoCoin.Blockchain.create(first)
    second = CryptoCoin.Block.create("second_block", first, 2, nil, 3)
    chain = CryptoCoin.Blockchain.add(second, chain)
    third = CryptoCoin.Block.create("third_block", second, 2, nil, 3)
    chain = CryptoCoin.Blockchain.add(third, chain)
    fourth = CryptoCoin.Block.create("fourth_block", third, 2, nil, 3)
    chain = CryptoCoin.Blockchain.add(fourth, chain)
    assert CryptoCoin.Blockchain.is_valid(chain) == true
  end

  test "blockchain is invalid" do
    first = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    chain = CryptoCoin.Blockchain.create(first)
    second = CryptoCoin.Block.create("second_block", first, 2, nil, 3)
    chain = CryptoCoin.Blockchain.add(second, chain)
    third = CryptoCoin.Block.create("third_block", second, 2, nil, 3)
    fourth = CryptoCoin.Block.create("fourth_block", third, 2, nil, 3)
    # Invalid order in the chain
    chain = CryptoCoin.Blockchain.add(fourth, chain)
    chain = CryptoCoin.Blockchain.add(third, chain)
    assert CryptoCoin.Blockchain.is_valid(chain) == false
  end
end
