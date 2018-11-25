defmodule TestUtils do
  def create_empty_blockchain() do
    CryptoCoin.Blockchain.create()
  end

  def create_valid_block() do
    CryptoCoin.Block.create(
      "0F74BE448F6DC9D646ACB7656B2895BBF85FBD4035E3C60705A2F4EA788CE01B",
      nil,
      1,
      [],
      1
    )
  end

  def create_valid_blockchain() do
    first = create_valid_block()
    CryptoCoin.Blockchain.create(first)
  end

  def create_valid_blockchain1() do
    first = create_valid_block()
    chain = CryptoCoin.Blockchain.create(first)

    second =
      CryptoCoin.Block.create(
        "009C71591CED1C40DDF5C50DE260CCD6F043C54BDC48349C581D85FAFAD06E97",
        first,
        690,
        [TestUtils.create_valid_transaction()],
        2
      )

    CryptoCoin.Blockchain.add(second, chain)
  end

  def create_valid_blockchain2() do
    first = create_valid_block()
    chain = CryptoCoin.Blockchain.create(first)

    second =
      CryptoCoin.Block.create(
        "009C71591CED1C40DDF5C50DE260CCD6F043C54BDC48349C581D85FAFAD06E97",
        first,
        690,
        [TestUtils.create_valid_transaction()],
        2
      )

    chain = CryptoCoin.Blockchain.add(second, chain)

    third =
      CryptoCoin.Block.create(
        "0065943F7C84431D3B12136BD49332448696CA6A4519CC1A97936211ECF47433",
        second,
        900,
        create_valid_transactions(),
        2
      )

    CryptoCoin.Blockchain.add(third, chain)
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
