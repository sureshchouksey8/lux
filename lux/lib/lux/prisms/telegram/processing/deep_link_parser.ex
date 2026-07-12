defmodule Lux.Prisms.Telegram.Processing.DeepLinkParser do
  @moduledoc """
  A prism for parsing Telegram deep linking payloads.
  
  When a user clicks a deep link (e.g., t.me/bot?start=payload), the bot receives
  a message like "/start payload". This prism extracts and decodes the payload.
  """

  use Lux.Prism,
    name: "Telegram Deep Link Parser",
    description: "Parses Telegram deep linking payloads",
    input_schema: %{
      type: :object,
      properties: %{
        text: %{type: :string}
      },
      required: ["text"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        is_deep_link: %{type: :boolean},
        payload: %{type: :string}
      },
      required: ["is_deep_link"]
    }

  def handler(%{text: text}, _agent) when is_binary(text) do
    if String.starts_with?(text, "/start ") do
      # Extract everything after "/start "
      payload = String.slice(text, 7..-1//1)
      {:ok, %{is_deep_link: true, payload: String.trim(payload)}}
    else
      {:ok, %{is_deep_link: false, payload: nil}}
    end
  end
  
  def handler(_params, _agent) do
    {:ok, %{is_deep_link: false, payload: nil}}
  end
end
