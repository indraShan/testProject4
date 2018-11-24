defmodule CryptoCoin.Block do
  def create(hash, prev_block, nonce, trasanctions, diff) do
    prev_hash =
      if prev_block != nil do
        Map.get(prev_block, "hash")
      else
        nil
      end

    %{
      "diff" => diff,
      "hash" => hash,
      "prev_hash" => prev_hash,
      "nonce" => nonce,
      "trasanctions" => trasanctions
    }
  end

  # Returns all transactions contained in the block
  def get_trasactions(block) do
    block |> Map.get("trasanctions")
  end

  # Verifies if the block's prev_hash is equal to parent_block's hash
  def verify_block_parent(block, parent_block) do
    Map.get(block, "prev_hash") == Map.get(parent_block, "hash")
  end

  def is_valid(_) do
    # Check if hash(prev_hash+trasactions+nounce) == diff
    true
  end
end
