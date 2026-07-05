defmodule Lux.Prisms.Telegram.GroupManagement.BanChatMember do
  @moduledoc """
  A prism for banning a user in a supergroup or a channel via the Telegram Bot API.

  In the case of supergroups and channels, the user will not be able to return to the chat on their own using invite links, etc., unless unbanned first.
  """

  use Lux.Prism,
    name: "Ban Telegram Chat Member",
    description: "Bans a user in a supergroup or a channel.",
    input_schema: %{
      type: :object,
      properties: %{
        chat_id: %{
          type: [:string, :integer],
          description: "Unique identifier for the target group or username of the target supergroup or channel"
        },
        user_id: %{
          type: :integer,
          description: "Unique identifier of the target user"
        },
        until_date: %{
          type: :integer,
          description: "Date when the user will be unbanned; Unix time."
        },
        revoke_messages: %{
          type: :boolean,
          description: "Pass True to delete all messages from the chat for the user that is being removed."
        }
      },
      required: ["chat_id", "user_id"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        success: %{
          type: :boolean,
          description: "Whether the member was successfully banned"
        }
      },
      required: ["success"]
    }

  alias Lux.Integrations.Telegram.Client
  require Logger

  def handler(params, agent) do
    with {:ok, chat_id} <- validate_param(params, :chat_id),
         {:ok, user_id} <- validate_param(params, :user_id) do

      agent_name = agent[:name] || "Unknown Agent"
      Logger.info("Agent #{agent_name} banning user #{user_id} in chat #{chat_id}")

      request_body = Map.take(params, [:chat_id, :user_id, :until_date, :revoke_messages])
      request_opts = %{json: request_body}

      case Client.request(:post, "/banChatMember", request_opts) do
        {:ok, %{"result" => true}} ->
          Logger.info("Successfully banned user #{user_id} in chat #{chat_id}")
          {:ok, %{success: true}}

        {:error, {status, %{"description" => description}}} ->
          error = "Failed to ban chat member: #{description} (HTTP #{status})"
          {:error, error}

        {:error, {status, description}} when is_binary(description) ->
          error = "Failed to ban chat member: #{description} (HTTP #{status})"
          {:error, error}

        {:error, error} ->
          {:error, "Failed to ban chat member: #{inspect(error)}"}
      end
    end
  end

  defp validate_param(params, key) do
    case Map.fetch(params, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      {:ok, value} when is_integer(value) -> {:ok, value}
      _ -> {:error, "Missing or invalid #{key}"}
    end
  end
end
