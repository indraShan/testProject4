defmodule CryptoCoin.Blockchain do
  def create() do
    %{}
  end

  def create(block) do
    %{1 => block}
  end

  def add(block, chain) do
    size = Map.size(chain)
    Map.put(chain, size + 1, block)
  end

  def get_last_block(chain) do
    size = Map.size(chain)

    if size != 0 do
      Map.get(chain, size)
    else
      nil
    end
  end

  def unspent_transactions(public_key, private_key, chain) do
    transactions = get_trasactions(chain)

    # balance = (outs where private_key can unlock) - (ins where the keys from outs are present)

    utxos =
      Enum.reduce(transactions, %{}, fn transaction, acc ->
        outputs = CryptoCoin.Transaction.get_outputs(transaction, private_key)

        Enum.reduce(outputs, acc, fn output, map ->
          map |> Map.put(CryptoCoin.TransactionUnit.get_unique_id(output), output)
        end)
      end)

    # IO.inspect(utxos)

    spent_units =
      Enum.reduce(transactions, [], fn transaction, acc ->
        inputs = CryptoCoin.Transaction.get_inputs(transaction, public_key)

        Enum.reduce(inputs, acc, fn input, list ->
          [CryptoCoin.TransactionUnit.get_unique_id(input)] ++ list
        end)
      end)

    utxos = utxos |> Map.drop(spent_units)
    utxos |> Map.values()
  end

  # Collects all trasactions from the block chain
  # Returns a list.
  def get_trasactions(chain) do
    keys = Map.keys(chain)

    trasactions =
      Enum.reduce(keys, [], fn key, acc ->
        block = chain |> Map.get(key)
        trasactions = block |> CryptoCoin.Block.get_trasactions()
        trasactions ++ acc
      end)
  end

  def is_valid(chain) do
    # Check if the blocks are in order. that is the hashes of blocks are equal.
    # Check if all the blocks are valid
    # valid_chain = Enum.filter(chain, fn(block) -> CryptoCoin.Block.is_valid(block) end)
    # length(valid_chain) == length(chain)

    sorted_keys = Enum.sort(Map.keys(chain))

    valid_keys =
      Enum.filter(sorted_keys, fn key ->
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
