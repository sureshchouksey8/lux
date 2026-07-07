defmodule Lux.Schemas.MultiChain.Log do
  @moduledoc """
  A normalized struct for multi-chain log/event data.
  """
  @enforce_keys [:chain_id, :block_number, :tx_hash, :log_index, :contract_address]
  defstruct [
    :chain_id,
    :block_number,
    :tx_hash,
    :log_index,
    :contract_address,
    :topic_schema,
    :dedupe_key,
    :data,
    :topics,
    :raw_log
  ]
end

defmodule Lux.Schemas.MultiChain.Transaction do
  @moduledoc """
  A normalized struct for multi-chain transaction data.
  """
  @enforce_keys [:chain_id, :block_number, :tx_hash]
  defstruct [
    :chain_id,
    :block_number,
    :tx_hash,
    :from,
    :to,
    :value,
    :status,
    :gas_used,
    :dedupe_key,
    :raw_tx
  ]
end
