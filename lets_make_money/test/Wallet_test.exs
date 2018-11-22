defmodule WalletTest do
  use ExUnit.Case

  setup %{} do
    {:ok, wallet} = CryptoCoin.Wallet.create("public", "private_dont_read_this")
    {:ok, wallet: wallet}
  end

  test "wallet blockchain update", %{wallet: wallet} do
    chain = TestUtils.create_valid_blockchan()
    CryptoCoin.Wallet.handle_blockchain_broadcast(wallet, chain)

    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 30}, 100
  end
end
