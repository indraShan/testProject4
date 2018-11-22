defmodule TestUtils do
  def create_valid_blockchan() do
    first = CryptoCoin.Block.create("first_block", nil, 2, nil, 3)
    chain = CryptoCoin.Blockchain.create(first)
    second = CryptoCoin.Block.create("second_block", first, 2, nil, 3)
    chain = CryptoCoin.Blockchain.add(second, chain)
    third = CryptoCoin.Block.create("third_block", second, 2, nil, 3)
    chain = CryptoCoin.Blockchain.add(third, chain)
    fourth = CryptoCoin.Block.create("fourth_block", third, 2, nil, 3)
    CryptoCoin.Blockchain.add(fourth, chain)
  end
end
