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

  test "get transactions" do
    first =
      CryptoCoin.Block.create("first_block", nil, 2, [TestUtils.create_valid_transaction()], 3)

    chain = CryptoCoin.Blockchain.create(first)

    second =
      CryptoCoin.Block.create("second_block", first, 2, TestUtils.create_valid_transactions(), 3)

    chain = CryptoCoin.Blockchain.add(second, chain)

    transactions = CryptoCoin.Blockchain.get_trasactions(chain)
    assert length(transactions) == 3
  end

  test "unspent transactions" do
    chain = TestUtils.create_valid_blockchan()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key1", "key1", chain)
    assert length(utxos) == 1

    unit = utxos |> Enum.at(0)
    assert CryptoCoin.TransactionUnit.get_amount(unit) == 2

    utxos = CryptoCoin.Blockchain.unspent_transactions("key2", "key2", chain)
    assert length(utxos) == 2

    amount =
      CryptoCoin.TransactionUnit.get_amount(utxos |> Enum.at(0)) +
        CryptoCoin.TransactionUnit.get_amount(utxos |> Enum.at(1))

    assert amount == 23

    utxos = CryptoCoin.Blockchain.unspent_transactions("key3", "key3", chain)
    assert length(utxos) == 3

    amount =
      CryptoCoin.TransactionUnit.get_amount(utxos |> Enum.at(0)) +
        CryptoCoin.TransactionUnit.get_amount(utxos |> Enum.at(1)) +
        CryptoCoin.TransactionUnit.get_amount(utxos |> Enum.at(2))

    assert amount == 35
  end
end
