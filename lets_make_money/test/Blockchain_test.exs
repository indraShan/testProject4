defmodule BlockchainTest do
  use ExUnit.Case

  test "block chain creation" do
    block = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    chain = CryptoCoin.Blockchain.create(block)
    assert chain != nil
  end

  test "verify is_equal" do
    chain1 = TestUtils.create_valid_blockchain()
    chain2 = TestUtils.create_valid_blockchain()
    assert CryptoCoin.Blockchain.is_equal(chain1, chain2) == true

    chain3 = TestUtils.create_valid_blockchain2()
    assert CryptoCoin.Blockchain.is_equal(chain3, chain1) == false
  end

  test "block chain add and last block" do
    block = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)

    chain = CryptoCoin.Blockchain.create(block)
    assert CryptoCoin.Blockchain.get_last_block(chain) == block

    second = CryptoCoin.Block.create("second_block", block, 2, nil, 3)
    chain = CryptoCoin.Blockchain.add(second, chain)

    assert CryptoCoin.Blockchain.get_last_block(chain) == second
  end

  test "chain length" do
    block = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    chain = CryptoCoin.Blockchain.create(block)
    assert CryptoCoin.Blockchain.chain_length(chain) == 1

    second = CryptoCoin.Block.create("second_block", block, 2, nil, 3)
    chain = CryptoCoin.Blockchain.add(second, chain)

    assert CryptoCoin.Blockchain.chain_length(chain) == 2
  end

  test "blockchain is valid 1" do
    assert CryptoCoin.Blockchain.is_valid(TestUtils.create_valid_blockchain()) == true
  end

  test "blockchain is valid 2" do
    assert CryptoCoin.Blockchain.is_valid(TestUtils.create_valid_blockchain1()) == true
  end

  test "blockchain is valid 3" do
    assert CryptoCoin.Blockchain.is_valid(TestUtils.create_valid_blockchain2()) == true
  end

  test "blockchain is invalid" do
    first = TestUtils.create_valid_block()
    chain = CryptoCoin.Blockchain.create(first)

    second =
      CryptoCoin.Block.create(
        "009C71591CED1C40DDF5C50DE260CCD6F043C54BDC48349C581D85FAFAD06E97",
        first,
        690,
        [TestUtils.create_valid_transaction()],
        2
      )

    third =
      CryptoCoin.Block.create(
        "0065943F7C84431D3B12136BD49332448696CA6A4519CC1A97936211ECF47433",
        second,
        900,
        TestUtils.create_valid_transactions(),
        2
      )

    chain = CryptoCoin.Blockchain.add(third, chain)
    chain = CryptoCoin.Blockchain.add(second, chain)

    assert CryptoCoin.Blockchain.is_valid(chain) == false
  end

  test "blockchain is invalid2" do
    first = TestUtils.create_valid_block()
    chain = CryptoCoin.Blockchain.create(first)

    third =
      CryptoCoin.Block.create(
        "0065943F7C84431D3B12136BD49332448696CA6A4519CC1A97936211ECF47433",
        first,
        900,
        TestUtils.create_valid_transactions(),
        2
      )

    second =
      CryptoCoin.Block.create(
        "009C71591CED1C40DDF5C50DE260CCD6F043C54BDC48349C581D85FAFAD06E97",
        third,
        690,
        [TestUtils.create_valid_transaction()],
        2
      )

    chain = CryptoCoin.Blockchain.add(second, chain)
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
    chain = TestUtils.create_valid_blockchain2()
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
