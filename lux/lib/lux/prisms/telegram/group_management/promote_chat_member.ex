defmodule Lux.Prisms.Telegram.GroupManagement.PromoteChatMember do
  @moduledoc """
  A prism for promoting or demoting a user in a supergroup or channel via the Telegram Bot API.

  The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights.
  """

  use Lux.Prism,
    name: "Promote Telegram Chat Member",
    description: "Promotes or demotes a user in a supergroup or channel.",
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
        is_anonymous: %{type: :boolean},
        can_manage_chat: %{type: :boolean},
        can_delete_messages: %{type: :boolean},
        can_manage_video_chats: %{type: :boolean},
        can_restrict_members: %{type: :boolean},
        can_promote_members: %{type: :boolean},
        can_change_info: %{type: :boolean},
        can_invite_users: %{type: :boolean},
        can_post_stories: %{type: :boolean},
        can_edit_stories: %{type: :boolean},
        can_delete_stories: %{type: :boolean},
        can_post_messages: %{type: :boolean},
        can_edit_messages: %{type: :boolean},
        can_pin_messages: %{type: :boolean},
        can_manage_topics: %{type: :boolean}
      },
      required: ["chat_id", "user_id"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        success: %{
          type: :boolean,
          description: "Whether the member was successfully promoted or demoted"
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
      Logger.info("Agent #{agent_name} promoting user #{user_id} in chat #{chat_id}")

      request_body = Map.take(params, [
        :chat_id, :user_id, :is_anonymous, :can_manage_chat, :can_delete_messages,
        :can_manage_video_chats, :can_restrict_members, :can_promote_members,
        :can_change_info, :can_invite_users, :can_post_stories, :can_edit_stories,
        :can_delete_stories, :can_post_messages, :can_edit_messages, :can_pin_messages,
        :can_manage_topics
      ])

      request_opts = %{json: request_body}

      case Client.request(:post, "/promoteChatMember", request_opts) do
        {:ok, %{"result" => true}} ->
          Logger.info("Successfully promoted/demoted user #{user_id} in chat #{chat_id}")
          {:ok, %{success: true}}

        {:error, {status, %{"description" => description}}} ->
          error = "Failed to promote chat member: #{description} (HTTP #{status})"
          {:error, error}

        {:error, {status, description}} when is_binary(description) ->
          error = "Failed to promote chat member: #{description} (HTTP #{status})"
          {:error, error}

        {:error, error} ->
          {:error, "Failed to promote chat member: #{inspect(error)}"}
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
