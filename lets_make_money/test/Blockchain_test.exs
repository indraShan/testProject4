defmodule BlockchainTest do
  use ExUnit.Case

  test "block creation" do
    block = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    assert block != nil
  end
end
