defmodule CryptoCoin.Block do
  def genesis_string() do
    "genesis"
  end

  def create(hash, prev_block, nonce, trasanctions, diff) do
    prev_hash =
      if prev_block != nil do
        Map.get(prev_block, "hash")
      else
        # Assumption: if prev block is null,
        # this is the first block of system which derives from
        # genesis block
        genesis_string()
      end

    %{
      "diff" => diff,
      "hash" => hash,
      "prev_hash" => prev_hash,
      "nonce" => nonce,
      "trasanctions" => trasanctions
    }
  end

  def get_hash(block) do
    block |> Map.get("hash")
  end

  def get_nonce(block) do
    block |> Map.get("nonce")
  end

  # Returns all transactions contained in the block
  def get_trasactions(block) do
    block |> Map.get("trasanctions")
  end

  # Verifies if the block's prev_hash is equal to parent_block's hash
  def verify_block_parent(block, parent_block) do
    Map.get(block, "prev_hash") == Map.get(parent_block, "hash")
  end

  def is_valid(block) do
    hash_valid = has_valid_hash(block)

    if hash_valid == true do
      transactions = get_trasactions(block)

      valid_transactions =
        Enum.filter(transactions, fn transaction ->
          CryptoCoin.Transaction.is_valid(transaction)
        end)

      length(valid_transactions) == length(transactions)
    else
      hash_valid
    end
  end

  # Given a block checks if the hash is valid.
  # i.e. hash(prev_hash+trasactions+nounce) == diff && calc_hash == set_hash
  defp has_valid_hash(block) do
    prev_hash = block |> Map.get("prev_hash")
    transactions = get_trasactions(block)
    encoded_transactions = CryptoCoin.Utils.encode(transactions)
    nonce = get_nonce(block)
    data = prev_hash <> encoded_transactions <> Integer.to_string(nonce)
    current_hash = get_hash(block)
    hash_valid = CryptoCoin.Utils.hash(data) == current_hash

    if hash_valid == true do
      diff = block |> Map.get("diff")
      diff_prefix = CryptoCoin.Utils.prefixStringForDifficultyLevel(diff)
      hash_prefix = String.slice(current_hash, 0, diff)
      hash_prefix == diff_prefix
    else
      hash_valid
    end
  end
end
