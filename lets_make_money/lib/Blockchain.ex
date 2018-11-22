defmodule CryptoCoin.Blockchain do
  def create(block) do
    %{1 => block}
  end

  def add(block, chain) do
    size = Map.size(chain)
    Map.put(chain, size + 1, block)
  end

  def get_last_block(chain) do
    size = Map.size(chain)
    Map.get(chain, size)
  end

  def is_valid(chain) do
    # Check if the blocks are in order. that is the hashes of blocks are equal.
    # Check if all the blocks are valid
    # valid_chain = Enum.filter(chain, fn(block) -> CryptoCoin.Block.is_valid(block) end)
    # length(valid_chain) == length(chain)

    sorted_keys = Enum.sort(Map.keys(chain))

    valid_keys = Enum.filter(sorted_keys, fn key ->
      valid = true
      block = Map.get(chain, key)
      previous_key = key - 1

      valid =
        if previous_key != 0 do
          prev_block = Map.get(chain, previous_key)
          CryptoCoin.Block.verify_block_parent(block, prev_block)
        else
          valid
        end

      if valid == true do
        CryptoCoin.Block.is_valid(block)
      else
        valid
      end
    end)
    # true if the length of valid keys is equal to all keys
    length(valid_keys) == length(sorted_keys)
  end
end
