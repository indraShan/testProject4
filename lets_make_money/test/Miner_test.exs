defmodule MinerTest do
  use ExUnit.Case

  test "mine a block callback" do
    {:ok, miner} = CryptoCoin.Miner.start(self())
    chain = TestUtils.create_valid_blockchain2()

    inputs = []
    inputs = [CryptoCoin.TransactionUnit.create("key3", 10, "id:9")] ++ inputs
    outputs = []
    outputs = [CryptoCoin.TransactionUnit.create("key1", 10, "id:13")] ++ outputs
    transactions = [CryptoCoin.Transaction.create(inputs, outputs)]

    send(miner, {:mine, chain, transactions, 1})
    assert_receive {:found_a_block, chain, _, _}, 300
  end

  test "mine genesis block" do
    chain = TestUtils.create_empty_blockchain()
    block = CryptoCoin.Miner.mine(chain, [], 1, self())
    hash = CryptoCoin.Block.get_hash(block)
    prefix = String.slice(hash, 0, 1)
    assert prefix == "0"
    chain = CryptoCoin.Blockchain.add(block, chain)
    assert CryptoCoin.Blockchain.is_valid(chain) == true
  end

  test "mine a block" do
    inputs = []
    inputs = [CryptoCoin.TransactionUnit.create("key3", 10, "id:9")] ++ inputs
    outputs = []
    outputs = [CryptoCoin.TransactionUnit.create("key1", 10, "id:13")] ++ outputs
    transactions = [CryptoCoin.Transaction.create(inputs, outputs)]

    chain = TestUtils.create_valid_blockchain2()
    block = CryptoCoin.Miner.mine(chain, transactions, 2, self())
    hash = CryptoCoin.Block.get_hash(block)
    prefix = String.slice(hash, 0, 2)
    assert prefix == "00"

    assert CryptoCoin.Block.is_valid(block) == true
  end

  test "mine a block for multiple transactions in one block" do
    inputs = []
    inputs = [CryptoCoin.TransactionUnit.create("key3", 10, "id:9")] ++ inputs
    outputs = []
    outputs = [CryptoCoin.TransactionUnit.create("key1", 10, "id:13")] ++ outputs
    transactions = [CryptoCoin.Transaction.create(inputs, outputs)]

    inputs = []
    inputs = [CryptoCoin.TransactionUnit.create("key1", 10, "id:13")] ++ inputs
    outputs = []
    outputs = [CryptoCoin.TransactionUnit.create("key1", 5, "id:15")] ++ outputs
    outputs = [CryptoCoin.TransactionUnit.create("key2", 5, "id:16")] ++ outputs
    transactions = [CryptoCoin.Transaction.create(inputs, outputs)] ++ transactions

    chain = TestUtils.create_valid_blockchain2()
    block = CryptoCoin.Miner.mine(chain, transactions, 3, self())
    hash = CryptoCoin.Block.get_hash(block)
    prefix = String.slice(hash, 0, 3)
    assert prefix == "000"

    assert CryptoCoin.Block.is_valid(block) == true
  end
end
