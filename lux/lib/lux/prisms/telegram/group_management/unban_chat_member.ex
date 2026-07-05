defmodule Lux.Prisms.Telegram.GroupManagement.UnbanChatMember do
  @moduledoc """
  A prism for unbanning a previously banned user in a supergroup or channel via the Telegram Bot API.

  The user will not return to the group or channel automatically, but will be able to join via link, etc.
  """

  use Lux.Prism,
    name: "Unban Telegram Chat Member",
    description: "Unbans a previously banned user in a supergroup or channel.",
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
        only_if_banned: %{
          type: :boolean,
          description: "Do nothing if the user is not banned"
        }
      },
      required: ["chat_id", "user_id"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        success: %{
          type: :boolean,
          description: "Whether the member was successfully unbanned"
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
      Logger.info("Agent #{agent_name} unbanning user #{user_id} in chat #{chat_id}")

      request_body = Map.take(params, [:chat_id, :user_id, :only_if_banned])
      request_opts = %{json: request_body}

      case Client.request(:post, "/unbanChatMember", request_opts) do
        {:ok, %{"result" => true}} ->
          Logger.info("Successfully unbanned user #{user_id} in chat #{chat_id}")
          {:ok, %{success: true}}

        {:error, {status, %{"description" => description}}} ->
          error = "Failed to unban chat member: #{description} (HTTP #{status})"
          {:error, error}

        {:error, {status, description}} when is_binary(description) ->
          error = "Failed to unban chat member: #{description} (HTTP #{status})"
          {:error, error}

        {:error, error} ->
          {:error, "Failed to unban chat member: #{inspect(error)}"}
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
