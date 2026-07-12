defmodule Lux.Prisms.Telegram.Processing.ReplyParser do
  @moduledoc """
  A prism for parsing Telegram message replies.
  """

  use Lux.Prism,
    name: "Telegram Reply Parser",
    description: "Extracts information about the message being replied to",
    input_schema: %{
      type: :object,
      properties: %{
        message: %{
          type: :object,
          description: "Telegram message object"
        }
      },
      required: ["message"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        is_reply: %{type: :boolean},
        replied_message_id: %{type: :integer},
        replied_user_id: %{type: :integer},
        replied_text: %{type: :string}
      },
      required: ["is_reply"]
    }

  def handler(%{message: message}, _agent) when is_map(message) do
    message = stringify_keys(message)
    
    reply_to = message["reply_to_message"]
    
    if reply_to do
      {:ok, %{
        is_reply: true,
        replied_message_id: reply_to["message_id"],
        replied_user_id: get_in(reply_to, ["from", "id"]),
        replied_text: reply_to["text"] || reply_to["caption"]
      }}
    else
      {:ok, %{
        is_reply: false,
        replied_message_id: nil,
        replied_user_id: nil,
        replied_text: nil
      }}
    end
  end
  
  def handler(%{"message" => message}, agent) when is_map(message) do
    handler(%{message: message}, agent)
  end
  
  def handler(_params, _agent) do
    {:error, "Missing required parameter: message"}
  end
  
  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
