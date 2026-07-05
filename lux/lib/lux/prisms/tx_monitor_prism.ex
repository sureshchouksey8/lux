defmodule Lux.Prisms.TxMonitorPrism do
  @moduledoc """
  Monitors a transaction status on a specific chain by checking its receipt.
  """
  use Lux.Prism,
    name: "Transaction Monitor",
    description: "Monitors the status of a transaction on a given chain",
    input_schema: %{
      type: :object,
      properties: %{
        chain: %{
          type: :string,
          description: "Chain identifier (e.g., ethereum, polygon)"
        },
        tx_hash: %{
          type: :string,
          description: "Transaction hash"
        }
      },
      required: ["chain", "tx_hash"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        status: %{
          type: :string,
          description: "Transaction status: success, failed, or pending"
        },
        receipt: %{
          type: [:object, :null],
          description: "Transaction receipt if available"
        }
      },
      required: ["status"]
    }

  def handler(%{chain: chain, tx_hash: tx_hash}, ctx) do
    input = %{chain: chain, method: "eth_getTransactionReceipt", params: [tx_hash]}

    case Lux.Prisms.MultiChainRpcPrism.handler(input, ctx) do
      {:ok, %{result: nil}} ->
        {:ok, %{status: "pending", receipt: nil}}

      {:ok, %{result: receipt = %{"status" => status_hex}}} ->
        status = if status_hex == "0x1", do: "success", else: "failed"
        {:ok, %{status: status, receipt: receipt}}

      {:ok, %{result: receipt}} ->
         {:ok, %{status: "success", receipt: receipt}}

      {:error, error} ->
        {:error, "Failed to monitor tx: #{error}"}
    end
  end
end
