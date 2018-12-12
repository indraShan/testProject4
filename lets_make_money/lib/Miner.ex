defmodule CryptoCoin.Miner do
  def start(caller) do
    Task.start(fn -> wait(caller) end)
  end

  # private methods
  defp wait(caller) do
    receive do
      {:mine, blockchain, transactions, diff} ->
        start_time = :os.system_time(:millisecond)
        {block, nounce} = mine(blockchain, transactions, diff, caller)
        end_time = :os.system_time(:millisecond)

        send(
          caller,
          {:found_a_block, blockchain, block, transactions, end_time - start_time, nounce}
        )

        wait(caller)
    end
  end

  # Starts mining to find a new block.
  def mine(blockchain, transactions, diff, caller) do
    last_block = CryptoCoin.Blockchain.get_last_block(blockchain)

    nonce =
      if last_block != nil do
        CryptoCoin.Block.get_nonce(last_block)
      else
        1
      end

    prev_hash =
      if last_block != nil do
        CryptoCoin.Block.get_hash(last_block)
      else
        CryptoCoin.Block.genesis_string()
      end

    {hash, found_nonce} =
      mine(
        prev_hash,
        CryptoCoin.Utils.encode(transactions),
        CryptoCoin.Utils.prefixStringForDifficultyLevel(diff),
        nonce,
        caller
      )

    {CryptoCoin.Block.create(hash, last_block, found_nonce, transactions, diff), found_nonce}
  end

  defp mine(prev_hash, transactions, diff, nonce, caller) do
    data = prev_hash <> transactions <> Integer.to_string(nonce)
    hash = CryptoCoin.Utils.hash(data)
    prefix = String.slice(hash, 0, String.length(diff))

    if prefix == diff do
      # Found the hash matching the given diff level
      {hash, nonce}
    else
      # Increase nonce and try again :(
      mine(prev_hash, transactions, diff, nonce + 1, caller)
    end
  end
end
