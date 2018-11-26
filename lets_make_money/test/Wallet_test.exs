defmodule WalletTest do
  use ExUnit.Case

  setup %{} do
    chain = TestUtils.create_valid_blockchain2()
    {:ok, wallet} = CryptoCoin.Wallet.create("key1", "key1")
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet, chain)

    {:ok, wallet2} = CryptoCoin.Wallet.create("key2", "key2")
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet2, chain)

    {:ok, wallet3} = CryptoCoin.Wallet.create("key3", "key3")
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet3, chain)

    {:ok, wallet1: wallet, wallet2: wallet2, wallet3: wallet3}
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

  test "wallet1->2 validate send money amount", %{wallet1: wallet, wallet2: wallet2} do
    # IO.puts "Checking validate send money"
    CryptoCoin.Wallet.send_money_validate(wallet, wallet2, 1, self())
    assert_receive {:send_money_valid, [2]}, 100
  end

  test "wallet2->1 validate send money amount", %{wallet2: wallet2, wallet1: wallet} do
    # IO.puts "Checking 0 amount transfer"
    CryptoCoin.Wallet.send_money_validate(wallet2, wallet, 0, self())
    assert_receive {:send_money_valid, []}, 100
  end

  test "wallet3->1 validate send money amount", %{wallet3: wallet3, wallet1: wallet} do
    # IO.puts "Checking validate send money for wallet3"
    CryptoCoin.Wallet.send_money_validate(wallet3, wallet, 7, self())
    assert_receive {:send_money_valid, [5, 10]}, 100
  end

  test "wallet2->3 validate send money amount", %{wallet3: wallet3, wallet2: wallet2} do
    # IO.puts "Checking validate send money for wallet2"
    CryptoCoin.Wallet.send_money_validate(wallet2, wallet3, 3, self())
    assert_receive {:send_money_valid, [3]}, 100
  end

  test "wallet1->3 validate send money amount", %{wallet3: wallet3, wallet1: wallet} do
    # IO.puts "Checking overdraft on wallet1"
    CryptoCoin.Wallet.send_money_validate(wallet, wallet3, 10, self())
    assert_receive {:send_money_valid, []}, 100
  end

  test "wallet3->2 validate send money amount", %{wallet3: wallet3, wallet2: wallet2} do
    # IO.puts "Checking validate send money for wallet2"
    CryptoCoin.Wallet.send_money_validate(wallet3, wallet2, 17, self())
    assert_receive {:send_money_valid, [5, 10, 20]}, 100
  end
end
