defmodule FullNodeTest do
  use ExUnit.Case

  setup %{} do
    chain = TestUtils.create_empty_blockchain()
    {:ok, node} = CryptoCoin.FullNode.start(chain, "key", "key", 500, 2)

    {:ok, wallet} = CryptoCoin.Wallet.create("key", "key")
    {:ok, wallet: wallet, node: node}
  end

  test "mine genesis block for empty chain", %{wallet: wallet, node: node} do
    CryptoCoin.FullNode.add_peer(node, self())
    CryptoCoin.FullNode.add_peer(node, wallet)
    assert_receive {:handle_blockchain_broadcast, _}, 600

    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 500}, 300
  end
end
