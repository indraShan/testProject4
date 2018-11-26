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

    {:ok, wallet4} = CryptoCoin.Wallet.create("key3", "key3")
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet4, TestUtils.create_empty_blockchain())

    {:ok, wallet5} = CryptoCoin.Wallet.create("key3", "key3")
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet4, nil)

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
end
