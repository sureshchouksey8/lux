# Multi-Chain Data Aggregation

The Multi-Chain Data Aggregation module provides core primitives for interacting with JSON-RPC nodes across different blockchain networks in a unified way.

## Supported Chains
- `ethereum` (Ethereum Mainnet)
- `polygon` (Polygon PoS)
- `arbitrum` (Arbitrum One)
- `bsc` or `binance_smart_chain` (Binance Smart Chain)

## Configuration
By default, the prism uses public RPC endpoints. To ensure high availability and prevent rate limits in production, you should override these with your own RPC provider URLs (e.g., Infura, Alchemy) in your application configuration:

```elixir
config :lux,
  eth_rpc_url: "https://mainnet.infura.io/v3/YOUR-PROJECT-ID",
  polygon_rpc_url: "https://polygon-rpc.com",
  arbitrum_rpc_url: "https://arb1.arbitrum.io/rpc",
  bsc_rpc_url: "https://bsc-dataseed.binance.org"
```

## Example Usage

The `MultiChainRpcPrism` accepts a standard payload specifying the chain, the RPC method, and an optional list of parameters. It gracefully handles both string-keyed inputs (such as parsed JSON from an external source) and atom-keyed inputs.

### Fetching the Latest Block Number (String Keys)
```elixir
Lux.Prisms.MultiChainRpcPrism.handler(%{
  "chain" => "bsc",
  "method" => "eth_blockNumber",
  "params" => []
}, %{name: "CryptoAgent"})
# => {:ok, %{result: "0x...", chain: "bsc"}}
```

### Fetching an Account Balance (Atom Keys)
```elixir
Lux.Prisms.MultiChainRpcPrism.handler(%{
  chain: "ethereum",
  method: "eth_getBalance",
  params: ["0x742d35Cc6634C0532925a3b844Bc454e4438f44e", "latest"]
}, %{name: "CryptoAgent"})
# => {:ok, %{result: "0x...", chain: "ethereum"}}
```

## Foundation Note

This implementation serves as a foundational layer for a robust multi-chain data aggregation system. Currently, it provides an explicit RPC extraction layer with built-in retry, backoff, and provider fallback, as well as cross-chain normalized schemas (`Lux.Schemas.MultiChain.Log` and `Lux.Schemas.MultiChain.Transaction`) and a basic durable DETS-based aggregate store (`Lux.Stores.MultiChainStore`). Future work will build upon this foundation to add backfill/stream cursor logic, advanced query interfaces, and complex cross-chain analytics.

## Notes
* **Data Storage / Retrieval:** This module provides the core RPC query primitives, normalized schemas, and a basic durable store. High-level indexing, batch storage, and time-series querying require integration with a database and are outside the scope of this core prism.
* **Error Handling:** The prism captures JSON-RPC error codes, HTTP status errors, and automatically handles rate limits and retries with backoff.
