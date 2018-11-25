defmodule CryptoCoin.FullNode do
  def start(chain, public_key, private_key) do
    GenServer.start_link(
      __MODULE__,
      [chain: chain, public_key: public_key, private_key: private_key],
      []
    )
  end

  def handle_blockchain_broadcast(pid, chain) do
    GenServer.cast(pid, {:handle_blockchain_broadcast, chain})
  end

  # Tries to extend the blockchain by including this
  # set of transactions into a new block.
  def confirm_trasactions(pid, trasactions) do
    GenServer.cast(pid, {:confirm_trasactions, trasactions})
  end

  # Private methods after this

  def init(opts) do
    {:ok, miner} = CryptoCoin.Miner.start(self())
    state = %{
      public_key: opts[:public_key],
      private_key: opts[:private_key],
      block_chain: opts[:chain],
      miner: miner
    }

    if CryptoCoin.Blockchain.chain_length(opts[:chain] == 0) do
      mine_genesis_block(state)
    end

    {:ok, state}
  end

  defp mine_genesis_block(state) do
    miner = state.miner

  end

  defp mining_reward_transaction(state) do
    # No input
    inputs = []
    outputs = []
    outputs = [CryptoCoin.TransactionUnit.create(state.public_key, 10, "id:13")] ++ outputs
    transaction = CryptoCoin.Transaction.create(inputs, outputs)
  end

  def handle_cast({:handle_blockchain_broadcast, chain}, state) do
    # If the received chain is shorter than the one this node
    # currently has, ignore it.
    {:noreply, state}
  end

end
