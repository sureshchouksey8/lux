defmodule Lux.Prisms.Telegram.GroupManagement.PromoteChatMember do
  @moduledoc """
  A prism for promotes or demotes a user in a supergroup or a channel via the Telegram Bot API.

  ## Examples

      iex> PromoteChatMember.handler(%{
      ...>   chat_id: 123_456_789,
...>   user_id: 987_654
      ...> }, %{name: "Agent"})
      {:ok, %{success: true, chat_id: 123_456_789}}
  """

  use Lux.Prism,
    name: "Promote Chat Member",
    description: "Promotes or demotes a user in a supergroup or a channel",
    input_schema: %{
      type: :object,
      properties: %{
        chat_id: %{
          type: [:string, :integer],
          description: "Unique identifier for the target chat"
        },
        user_id: %{
          type: :integer,
          description: "Unique identifier of the target user"
        },
        is_anonymous: %{
          type: :boolean,
          description: "Pass True, if the administrator's presence in the chat is hidden"
        },
        can_manage_chat: %{
          type: :boolean,
          description: "Pass True, if the administrator can access the chat event log, chat statistics, message statistics in channels, see channel members, see anonymous administrators in supergroups and ignore slow mode."
        }
      },
      required: ["chat_id", "user_id"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        success: %{
          type: :boolean,
          description: "Whether the operation was successful"
        },
        chat_id: %{
          type: [:string, :integer],
          description: "Identifier of the target chat"
        }
      },
      required: ["success", "chat_id"]
    }

  alias Lux.Integrations.Telegram.Client
  require Logger

  def handler(params, agent) do
    with {:ok, chat_id} <- validate_param(params, :chat_id),
         {:ok, _} <- validate_param(params, :user_id) do
      agent_name = agent[:name] || "Unknown Agent"
      Logger.info("Agent #{agent_name} attempting to promote member in chat #{chat_id}")

      request_body = Map.take(params, [:chat_id, :user_id, :is_anonymous, :can_manage_chat, :plug])
      request_opts = %{json: request_body}

      case Client.request(:post, "/promoteChatMember", request_opts) do
        {:ok, %{"result" => true}} ->
          Logger.info("Successfully completed promote member in chat #{chat_id}")
          {:ok, %{success: true, chat_id: chat_id}}

        {:error, {status, %{"description" => description}}} ->
          {:error, "Failed to promote member: #{description} (HTTP #{status})"}

        {:error, {status, description}} when is_binary(description) ->
          {:error, "Failed to promote member: #{description} (HTTP #{status})"}

        {:error, error} ->
          {:error, "Failed to promote member: #{inspect(error)}"}
      end
    end
  end

  defp validate_param(params, key) do
    case Map.fetch(params, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      {:ok, value} when is_integer(value) -> {:ok, value}
      {:ok, value} when is_map(value) -> {:ok, value}
      _ -> {:error, "Missing or invalid #{key}"}
    end
  end
end
