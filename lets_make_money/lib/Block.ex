defmodule CryptoCoin.Block do
  def create(hash, prev_hash, nonce, trasanctions, diff) do
    %{
      "diff" => diff,
      "hash" => hash,
      "prev_hash" => prev_hash,
      "nonce" => nonce,
      "trasanctions" => trasanctions
    }
  end

  # Verifies if the block's prev_hash is equal to parent_block's hash
  def verify_block_parent(block, parent_block) do
    Map.get(block, "prev_hash") == Map.get(parent_block, "hash")
  end

  def is_valid(block) do
    IO.puts("is_valid called ")
    # Check the hash of the block.
    # Check if included transactions are valid.
    true
  end
end
