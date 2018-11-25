defmodule WalletTest do
  use ExUnit.Case

  setup %{} do
    {:ok, wallet} = CryptoCoin.Wallet.create("key1", "key1")
    {:ok, wallet: wallet}
  end

  test "wallet blockchain update", %{wallet: wallet} do
    chain = TestUtils.create_valid_blockchain2()
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet, chain)

    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 2}, 100
  end
end
