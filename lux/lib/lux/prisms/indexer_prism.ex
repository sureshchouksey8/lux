defmodule Lux.Prisms.IndexerPrism do
  @moduledoc """
  Indexes events or logs from a specific chain and contract.
  """
  use Lux.Prism,
    name: "Blockchain Indexer",
    description: "Indexes events and logs from a specific chain and contract",
    input_schema: %{
      type: :object,
      properties: %{
        chain: %{
          type: :string,
          description: "Chain identifier (e.g., ethereum, polygon)"
        },
        contract_address: %{
          type: :string,
          description: "Contract address to index"
        },
        from_block: %{
          type: :string,
          description: "Starting block number in hex or \"latest\", \"earliest\"",
          default: "latest"
        },
        to_block: %{
          type: :string,
          description: "Ending block number in hex or \"latest\"",
          default: "latest"
        },
        topics: %{
          type: :array,
          description: "Array of topics to filter",
          default: []
        }
      },
      required: ["chain", "contract_address"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        logs: %{
          type: :array,
          description: "Indexed logs"
        }
      },
      required: ["logs"]
    }

  def handler(%{chain: chain, contract_address: contract_address} = input, ctx) do
    from_block = Map.get(input, :from_block, "latest")
    to_block = Map.get(input, :to_block, "latest")
    topics = Map.get(input, :topics, [])

    filter = %{
      address: contract_address,
      fromBlock: from_block,
      toBlock: to_block
    }

    filter = if Enum.empty?(topics), do: filter, else: Map.put(filter, :topics, topics)

    rpc_input = %{
      chain: chain,
      method: "eth_getLogs",
      params: [filter]
    }

    case Lux.Prisms.MultiChainRpcPrism.handler(rpc_input, ctx) do
      {:ok, %{result: logs}} when is_list(logs) ->
        {:ok, %{logs: logs}}

      {:ok, %{result: nil}} ->
        {:ok, %{logs: []}}

      {:error, error} ->
        {:error, "Failed to index logs: #{error}"}
    end
  end
end
