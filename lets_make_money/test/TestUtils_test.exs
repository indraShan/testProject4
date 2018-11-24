defmodule TestUtils do
  def create_valid_blockchan() do
    first = CryptoCoin.Block.create("first_block", nil, 2, [create_valid_transaction()], 3)
    chain = CryptoCoin.Blockchain.create(first)
    second = CryptoCoin.Block.create("second_block", first, 2, create_valid_transactions(), 3)
    CryptoCoin.Blockchain.add(second, chain)
  end

  def create_valid_transaction() do
    inputs = []
    inputs = [CryptoCoin.TransactionUnit.create("key1", 10, "id:1")] ++ inputs
    inputs = [CryptoCoin.TransactionUnit.create("key1", 50, "id:2")] ++ inputs
    outputs = []
    outputs = [CryptoCoin.TransactionUnit.create("key2", 20, "id:3")] ++ outputs
    outputs = [CryptoCoin.TransactionUnit.create("key3", 20, "id:4")] ++ outputs
    outputs = [CryptoCoin.TransactionUnit.create("key1", 20, "id:5")] ++ outputs

    CryptoCoin.Transaction.create(inputs, outputs)
  end

  def create_valid_transactions() do
    transactions = []
    inputs = []
    inputs = [CryptoCoin.TransactionUnit.create("key1", 20, "id:5")] ++ inputs
    outputs = []
    outputs = [CryptoCoin.TransactionUnit.create("key2", 10, "id:6")] ++ outputs
    outputs = [CryptoCoin.TransactionUnit.create("key3", 5, "id:7")] ++ outputs
    outputs = [CryptoCoin.TransactionUnit.create("key1", 5, "id:8")] ++ outputs

    transactions = [CryptoCoin.Transaction.create(inputs, outputs)] ++ transactions

    inputs2 = []
    inputs2 = [CryptoCoin.TransactionUnit.create("key1", 5, "id:8")] ++ inputs2
    inputs2 = [CryptoCoin.TransactionUnit.create("key2", 10, "id:6")] ++ inputs2
    outputs2 = []
    outputs2 = [CryptoCoin.TransactionUnit.create("key3", 10, "id:9")] ++ outputs2
    outputs2 = [CryptoCoin.TransactionUnit.create("key2", 3, "id:10")] ++ outputs2
    outputs2 = [CryptoCoin.TransactionUnit.create("key1", 2, "id:11")] ++ outputs2

    [CryptoCoin.Transaction.create(inputs2, outputs2)] ++ transactions
  end
end
