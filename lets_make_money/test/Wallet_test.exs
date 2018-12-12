defmodule WalletTest do
  use ExUnit.Case

  setup %{} do
    chain = TestUtils.create_valid_blockchain2()
    {:ok, wallet} = CryptoCoin.Wallet.create("key1", "key1")
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet, chain, self())

    {:ok, wallet2} = CryptoCoin.Wallet.create("key2", "key2")
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet2, chain, self())

    {:ok, wallet3} = CryptoCoin.Wallet.create("key3", "key3")
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet3, chain, self())

    {:ok, wallet4} = CryptoCoin.Wallet.create("key3", "key3")

    CryptoCoin.Wallet.handle_blockchain_broadcast(
      wallet4,
      TestUtils.create_empty_blockchain(),
      self()
    )

    {:ok, wallet5} = CryptoCoin.Wallet.create("key3", "key3")
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet4, nil, self())

    {:ok, wallet1: wallet, wallet2: wallet2, wallet3: wallet3, wallet4: wallet4, wallet5: wallet5}
  end

  test "wallet5 check balance", %{wallet5: wallet} do
    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 0}, 100
  end

  test "wallet4 check balance", %{wallet4: wallet} do
    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 0}, 100
  end

  test "wallet1 check balance", %{wallet1: wallet} do
    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 2}, 100
  end

  test "wallet2 check balance", %{wallet2: wallet2} do
    CryptoCoin.Wallet.get_balance(wallet2, self())
    assert_receive {:current_balance, 23}, 100
  end

  test "wallet3 check balance", %{wallet3: wallet3} do
    CryptoCoin.Wallet.get_balance(wallet3, self())
    assert_receive {:current_balance, 35}, 100
  end

  test "wallet1->2 validate send money amount" do
    # IO.puts "Checking validate send money"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key1", "key1", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(1.2, utxos)

    assert Enum.map(inputs, fn x -> CryptoCoin.TransactionUnit.get_amount(x) end) == [2]
  end

  test "wallet2->1 validate send money amount" do
    # IO.puts "Checking negative amount transfer"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key2", "key2", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(-2, utxos)
    assert Enum.map(inputs, fn x -> CryptoCoin.TransactionUnit.get_amount(x) end) == []
  end

  test "wallet3->1 validate send money amount" do
    # IO.puts "Checking validate send money for wallet3"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key3", "key3", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(7, utxos)
    assert Enum.map(inputs, fn x -> CryptoCoin.TransactionUnit.get_amount(x) end) == [5, 10]
  end

  test "wallet2->3 validate send money amount" do
    # IO.puts "Checking validate send money for wallet2"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key2", "key2", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(3, utxos)
    assert Enum.map(inputs, fn x -> CryptoCoin.TransactionUnit.get_amount(x) end) == [3]
  end

  test "wallet1->3 validate send money amount" do
    # IO.puts "Checking overdraft on wallet1"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key1", "key1", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(10, utxos)
    assert Enum.map(inputs, fn x -> CryptoCoin.TransactionUnit.get_amount(x) end) == []
  end

  test "wallet3->2 validate send money amount" do
    # IO.puts "Checking validate send money for wallet3"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key3", "key3", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(17, utxos)
    assert Enum.map(inputs, fn x -> CryptoCoin.TransactionUnit.get_amount(x) end) == [5, 10, 20]
  end

  test "wallet3->2 outputs" do
    # IO.puts "Checking outputs"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key3", "key3", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(17, utxos)
    outputs = CryptoCoin.Wallet.generate_outputs("key3", "key2", inputs, 17)
    assert outputs == %{"key2" => [5, 10, 2], "key3" => [18]}
  end

  test "wallet1->2 outputs" do
    # IO.puts "Checking outputs"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key1", "key1", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(10, utxos)
    outputs = CryptoCoin.Wallet.generate_outputs("key1", "key2", inputs, 10)
    assert outputs == %{}
  end

  test "wallet1->3 outputs" do
    # IO.puts "Checking outputs"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key1", "key1", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(1.2, utxos)
    outputs = CryptoCoin.Wallet.generate_outputs("key1", "key3", inputs, 1.2)
    assert outputs == %{"key1" => [0.8], "key3" => [1.2]}
  end

  test "wallet2->1 outputs" do
    # IO.puts "Checking outputs"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key2", "key2", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(-10, utxos)
    outputs = CryptoCoin.Wallet.generate_outputs("key2", "key1", inputs, -10)
    assert outputs == %{}
  end

  test "wallet2->3 outputs" do
    # IO.puts "Checking outputs"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key2", "key2", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(23, utxos)
    outputs = CryptoCoin.Wallet.generate_outputs("key2", "key3", inputs, 23)
    assert outputs == %{"key2" => [0], "key3" => [3, 20]}
  end

  test "wallet3->1 outputs" do
    # IO.puts "Checking outputs for 15 in key3"
    chain = TestUtils.create_valid_blockchain2()
    utxos = CryptoCoin.Blockchain.unspent_transactions("key3", "key3", chain)
    inputs = CryptoCoin.Wallet.send_money_validate(15, utxos)
    outputs = CryptoCoin.Wallet.generate_outputs("key3", "key1", inputs, 15)
    assert outputs == %{"key1" => [5, 10], "key3" => [0]}
  end
end
