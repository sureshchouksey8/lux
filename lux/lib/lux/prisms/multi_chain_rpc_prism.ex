defmodule Lux.Prisms.MultiChainRpcPrism do
  @moduledoc """
  A prism for making multi-chain JSON-RPC calls with retry, backoff, and fallback.
  """
  use Lux.Prism,
    name: "Multi-Chain RPC",
    description: "Executes JSON-RPC calls across multiple blockchains",
    input_schema: %{
      type: :object,
      properties: %{
        chain: %{
          type: :string,
          description: "Chain identifier (e.g., ethereum, polygon, arbitrum)"
        },
        method: %{
          type: :string,
          description: "RPC method to call"
        },
        params: %{
          type: :array,
          description: "Parameters for the RPC call",
          default: []
        }
      },
      required: ["chain", "method"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        result: %{
          type: [:object, :string, :array, :number, :boolean, :null],
          description: "RPC response result"
        },
        chain: %{
          type: :string,
          description: "Chain identifier"
        }
      },
      required: ["result", "chain"]
    }

  def handler(input, _ctx) do
    chain = Map.get(input, :chain) || Map.get(input, "chain")
    method = Map.get(input, :method) || Map.get(input, "method")
    params = Map.get(input, :params) || Map.get(input, "params") || []
    rpc_urls = get_rpc_urls(chain)

    if rpc_urls != [] do
      payload = %{
        jsonrpc: "2.0",
        method: method,
        params: params,
        id: System.unique_integer([:positive])
      }

      base_delay = Application.get_env(:lux, :retry_delay, 500)
      execute_request(chain, rpc_urls, payload, 3, base_delay)
    else
      {:error, "Unsupported chain: #{chain}"}
    end
  end

  defp execute_request(_chain, [], _payload, _retries, _delay), do: {:error, "All providers failed"}

  defp execute_request(chain, [url | rest_urls] = urls, payload, retries_left, delay) do
    req_options = Application.get_env(:lux, :req_options, [])

    req =
      Req.new(req_options)
      |> Req.Request.put_header("content-type", "application/json")
      |> Req.Request.put_option(:receive_timeout, 10_000)

    # Per-chain request throttling could be integrated here (e.g. using :timer.sleep based on a rate limiter)

    case Req.post(req, url: url, json: payload) do
      {:ok, %Req.Response{status: 200, body: %{"result" => result}}} ->
        {:ok, %{result: result, chain: chain}}

      {:ok, %Req.Response{status: 200, body: %{"error" => error}}} ->
        {:error, "RPC error: #{inspect(error)}"}

      {:ok, %Req.Response{status: 200, body: _malformed_body}} ->
        if retries_left > 0 do
          Process.sleep(delay)
          execute_request(chain, urls, payload, retries_left - 1, delay * 2)
        else
          execute_request(chain, rest_urls, payload, 3, 500)
        end

      {:ok, %Req.Response{status: status}} when status in [429, 500, 502, 503, 504] ->
        if retries_left > 0 do
          Process.sleep(delay)
          execute_request(chain, urls, payload, retries_left - 1, delay * 2)
        else
          execute_request(chain, rest_urls, payload, 3, 500)
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP error: #{status}"}

      {:error, _exception} ->
        if retries_left > 0 do
          Process.sleep(delay)
          execute_request(chain, urls, payload, retries_left - 1, delay * 2)
        else
          execute_request(chain, rest_urls, payload, 3, 500)
        end
    end
  end

  defp get_rpc_urls("ethereum") do
    Application.get_env(:lux, :eth_rpc_urls, [
      Application.get_env(:lux, :eth_rpc_url, "https://cloudflare-eth.com"),
      "https://eth.llamarpc.com"
    ])
  end

  defp get_rpc_urls("polygon") do
    Application.get_env(:lux, :polygon_rpc_urls, [
      Application.get_env(:lux, :polygon_rpc_url, "https://polygon-rpc.com"),
      "https://polygon.llamarpc.com"
    ])
  end

  defp get_rpc_urls("arbitrum") do
    Application.get_env(:lux, :arbitrum_rpc_urls, [
      Application.get_env(:lux, :arbitrum_rpc_url, "https://arb1.arbitrum.io/rpc"),
      "https://arbitrum.llamarpc.com"
    ])
  end

  defp get_rpc_urls("bsc") do
    Application.get_env(:lux, :bsc_rpc_urls, [
      Application.get_env(:lux, :bsc_rpc_url, "https://bsc-dataseed.binance.org")
    ])
  end

  defp get_rpc_urls("binance_smart_chain"), do: get_rpc_urls("bsc")
  defp get_rpc_urls(_), do: []
end
