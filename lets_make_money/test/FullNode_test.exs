defmodule FullNodeTest do
  use ExUnit.Case

  setup %{} do
    chain = TestUtils.create_empty_blockchain()
    {:ok, node} = CryptoCoin.FullNode.start(chain, "key", "key", 500, 2)
    {:ok, wallet} = CryptoCoin.Wallet.create("key", "key")

    chain2 = TestUtils.create_valid_blockchain2()
    {:ok, node2} = CryptoCoin.FullNode.start(chain2, "key2", "key2", 500, 2)
    {:ok, wallet2} = CryptoCoin.Wallet.create("key2", "key2")

    {:ok, wallet: wallet, node: node, node2: node2, wallet2: wallet2}
  end

  test "start a node with existing blockchain", %{wallet2: wallet, node2: node} do
    CryptoCoin.FullNode.add_peer(node, wallet)
    CryptoCoin.FullNode.add_peer(node, self())
    assert_receive {:handle_blockchain_broadcast, _}, 600
    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 23}, 300
  end

  test "mine genesis block for empty chain", %{wallet: wallet, node: node} do
    CryptoCoin.FullNode.add_peer(node, self())
    CryptoCoin.FullNode.add_peer(node, wallet)
    assert_receive {:handle_blockchain_broadcast, _}, 600

    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 500}, 300
  end
end
