defmodule FullNodeTest do
  use ExUnit.Case

  setup %{} do
    chain = TestUtils.create_empty_blockchain()
    {:ok, node} = CryptoCoin.FullNode.start(chain, "key", "key", 500, 2)
    CryptoCoin.FullNode.mine_genesis(node, 500)
    {:ok, wallet} = CryptoCoin.Wallet.create("key", "key")

    chain2 = TestUtils.create_valid_blockchain2()
    {:ok, node2} = CryptoCoin.FullNode.start(chain2, "key5", "key5", 500, 2)
    {:ok, wallet1} = CryptoCoin.Wallet.create("key1", "key1")
    {:ok, wallet2} = CryptoCoin.Wallet.create("key2", "key2")

    CryptoCoin.FullNode.add_wallet(node2, wallet1)
    CryptoCoin.FullNode.add_wallet(node2, wallet2)

    {:ok, wallet: wallet, node: node, node2: node2, wallet1: wallet1, wallet2: wallet2}
  end

  test "send money. Success. Sending half coins." do
    {:ok, node} = CryptoCoin.FullNode.start(%{}, "key", "key", 500, 2)
    CryptoCoin.FullNode.mine_genesis(node, 500)
    {:ok, nodesWallet} = CryptoCoin.Wallet.create("key", "key")
    CryptoCoin.Wallet.connected_with_full_node(nodesWallet, node)
    {:ok, walletA} = CryptoCoin.Wallet.create("key2", "key2")
    CryptoCoin.Wallet.connected_with_full_node(walletA, node)
    CryptoCoin.FullNode.add_wallet(node, self())
    assert_receive {:handle_blockchain_broadcast, _, _}, 600
    CryptoCoin.Wallet.send_money(nodesWallet, "key2", 10.5)
    assert_receive {:handle_blockchain_broadcast, _, _}, 600
    CryptoCoin.Wallet.get_balance(walletA, self())
    # Receiver should now have 10.5 coins
    assert_receive {:current_balance, 10.5}, 300
    # Nodes wallet should have 500-10.5 balance.
    CryptoCoin.Wallet.get_balance(nodesWallet, self())
    assert_receive {:current_balance, 989.5}, 300
  end

  test "send money. Failure. Sending negative number of coins." do
    {:ok, node} = CryptoCoin.FullNode.start(%{}, "key", "key", 500, 2)
    CryptoCoin.FullNode.mine_genesis(node, 500)
    {:ok, nodesWallet} = CryptoCoin.Wallet.create("key", "key")
    CryptoCoin.Wallet.connected_with_full_node(nodesWallet, node)
    {:ok, walletA} = CryptoCoin.Wallet.create("key2", "key2")
    CryptoCoin.Wallet.connected_with_full_node(walletA, node)
    CryptoCoin.FullNode.add_wallet(node, self())
    assert_receive {:handle_blockchain_broadcast, _, _}, 600
    CryptoCoin.Wallet.send_money(nodesWallet, "key2", -600)
    CryptoCoin.Wallet.get_balance(walletA, self())
    # Receiver dosnt receive anything.
    assert_receive {:current_balance, 0}, 300
    # Nodes wallet should stay at 500.
    CryptoCoin.Wallet.get_balance(nodesWallet, self())
    assert_receive {:current_balance, 500}, 300
  end

  test "send money. Failure. 500-600 == overspending." do
    {:ok, node} = CryptoCoin.FullNode.start(%{}, "key", "key", 500, 2)
    CryptoCoin.FullNode.mine_genesis(node, 500)
    {:ok, nodesWallet} = CryptoCoin.Wallet.create("key", "key")
    CryptoCoin.Wallet.connected_with_full_node(nodesWallet, node)
    {:ok, walletA} = CryptoCoin.Wallet.create("key2", "key2")
    CryptoCoin.Wallet.connected_with_full_node(walletA, node)
    CryptoCoin.FullNode.add_wallet(node, self())
    assert_receive {:handle_blockchain_broadcast, _, _}, 600
    CryptoCoin.Wallet.send_money(nodesWallet, "key2", 600)
    CryptoCoin.Wallet.get_balance(walletA, self())
    # Receiver dosnt receive anything.
    assert_receive {:current_balance, 0}, 300
    # Nodes wallet should stay at 500.
    CryptoCoin.Wallet.get_balance(nodesWallet, self())
    assert_receive {:current_balance, 500}, 300
  end

  test "send money. Success case. 500-10 == 990,10" do
    {:ok, node} = CryptoCoin.FullNode.start(%{}, "key", "key", 500, 2)
    CryptoCoin.FullNode.mine_genesis(node, 500)
    {:ok, nodesWallet} = CryptoCoin.Wallet.create("key", "key")
    CryptoCoin.Wallet.connected_with_full_node(nodesWallet, node)
    {:ok, walletA} = CryptoCoin.Wallet.create("key2", "key2")
    CryptoCoin.Wallet.connected_with_full_node(walletA, node)
    CryptoCoin.FullNode.add_wallet(node, self())
    assert_receive {:handle_blockchain_broadcast, _, _}, 600
    CryptoCoin.Wallet.send_money(nodesWallet, "key2", 10)
    assert_receive {:handle_blockchain_broadcast, _, _}, 600
    CryptoCoin.Wallet.get_balance(walletA, self())
    # Receiver should now have 10 coins
    assert_receive {:current_balance, 10}, 300
    # Nodes wallet should have 500-10 balance.
    CryptoCoin.Wallet.get_balance(nodesWallet, self())
    assert_receive {:current_balance, 990}, 300
  end

  test "start a node with existing blockchain", %{wallet1: wallet, node2: node} do
    CryptoCoin.FullNode.add_wallet(node, self())
    assert_receive {:handle_blockchain_broadcast, _, _}, 600
    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 2}, 300
  end

  test "start a node with existing blockchain 2", %{wallet2: wallet, node2: node} do
    CryptoCoin.FullNode.add_wallet(node, self())
    assert_receive {:handle_blockchain_broadcast, _, _}, 600
    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 23}, 300
  end

  test "mine genesis block for empty chain", %{wallet: wallet, node: node} do
    CryptoCoin.FullNode.add_wallet(node, self())
    CryptoCoin.FullNode.add_wallet(node, wallet)
    assert_receive {:handle_blockchain_broadcast, _, _}, 600

    CryptoCoin.Wallet.get_balance(wallet, self())
    assert_receive {:current_balance, 500}, 300
  end
end
