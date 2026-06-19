defmodule Lux.Prisms.Web3.CreateWalletPrism do
  @moduledoc """
  Lux Prism to generate a new Web3 wallet or import an existing private key.
  Encrypts the private key and spins up a dedicated TransactionManager process for the address.
  """

  use Lux.Prism,
    name: "Web3 Create Wallet",
    description: "Generates a new non-custodial wallet or imports an existing one, encrypting the private key and initializing its transaction manager",
    input_schema: %{
      type: :object,
      properties: %{
        private_key: %{
          type: :string,
          description: "Optional existing private key to import (hex string)"
        }
      }
    },
    output_schema: %{
      type: :object,
      properties: %{
        address: %{
          type: :string,
          description: "Derived public Ethereum address of the wallet"
        },
        encrypted_private_key: %{
          type: :string,
          description: "The AES-256-GCM encrypted private key payload"
        }
      },
      required: ["address", "encrypted_private_key"]
    }

  @impl true
  def handler(input, _ctx) do
    result =
      case Map.get(input, :private_key) do
        nil ->
          Lux.Web3.Wallet.generate_wallet()

        "0x" <> _ = hex_key ->
          case Lux.Web3.Wallet.derive_address(hex_key) do
            {:ok, address} -> {:ok, %{private_key: hex_key, address: address}}
            {:error, reason} -> {:error, reason}
          end

        raw_hex ->
          hex_key = "0x" <> raw_hex
          case Lux.Web3.Wallet.derive_address(hex_key) do
            {:ok, address} -> {:ok, %{private_key: hex_key, address: address}}
            {:error, reason} -> {:error, reason}
          end
      end

    case result do
      {:ok, %{private_key: pk, address: address}} ->
        case Lux.Web3.KeyManager.encrypt(pk) do
          {:ok, encrypted_pk} ->
            case Lux.Web3.TransactionManager.start_manager(address, encrypted_pk) do
              {:ok, _pid} ->
                {:ok, %{address: address, encrypted_private_key: encrypted_pk}}

              {:error, {:already_started, _pid}} ->
                {:ok, %{address: address, encrypted_private_key: encrypted_pk}}

              {:error, reason} ->
                {:error, "Failed to start transaction manager: #{inspect(reason)}"}
            end

          {:error, reason} ->
            {:error, "Failed to encrypt private key: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
