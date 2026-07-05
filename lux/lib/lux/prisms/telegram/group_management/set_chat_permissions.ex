defmodule Lux.Prisms.Telegram.GroupManagement.SetChatPermissions do
  @moduledoc """
  A prism for setting default chat permissions for all members via the Telegram Bot API.

  The bot must be an administrator in the group or a supergroup for this to work and must have the can_restrict_members administrator rights.
  """

  use Lux.Prism,
    name: "Set Telegram Chat Permissions",
    description: "Sets default chat permissions for all members.",
    input_schema: %{
      type: :object,
      properties: %{
        chat_id: %{
          type: [:string, :integer],
          description: "Unique identifier for the target group or username of the target supergroup"
        },
        permissions: %{
          type: :object,
          description: "A JSON object for new default chat permissions",
          properties: %{
            can_send_messages: %{type: :boolean},
            can_send_audios: %{type: :boolean},
            can_send_documents: %{type: :boolean},
            can_send_photos: %{type: :boolean},
            can_send_videos: %{type: :boolean},
            can_send_video_notes: %{type: :boolean},
            can_send_voice_notes: %{type: :boolean},
            can_send_polls: %{type: :boolean},
            can_send_other_messages: %{type: :boolean},
            can_add_web_page_previews: %{type: :boolean},
            can_change_info: %{type: :boolean},
            can_invite_users: %{type: :boolean},
            can_pin_messages: %{type: :boolean},
            can_manage_topics: %{type: :boolean}
          }
        },
        use_independent_chat_permissions: %{
          type: :boolean,
          description: "Pass True if chat permissions are set independently"
        }
      },
      required: ["chat_id", "permissions"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        success: %{
          type: :boolean,
          description: "Whether the permissions were successfully set"
        }
      },
      required: ["success"]
    }

  alias Lux.Integrations.Telegram.Client
  require Logger

  def handler(params, agent) do
    with {:ok, chat_id} <- validate_param(params, :chat_id),
         {:ok, permissions} <- validate_param(params, :permissions, :map) do

      agent_name = agent[:name] || "Unknown Agent"
      Logger.info("Agent #{agent_name} setting chat permissions in chat #{chat_id}")

      request_body = Map.take(params, [:chat_id, :permissions, :use_independent_chat_permissions])
      request_opts = %{json: request_body}

      case Client.request(:post, "/setChatPermissions", request_opts) do
        {:ok, %{"result" => true}} ->
          Logger.info("Successfully set chat permissions in chat #{chat_id}")
          {:ok, %{success: true}}

        {:error, {status, %{"description" => description}}} ->
          error = "Failed to set chat permissions: #{description} (HTTP #{status})"
          {:error, error}

        {:error, {status, description}} when is_binary(description) ->
          error = "Failed to set chat permissions: #{description} (HTTP #{status})"
          {:error, error}

        {:error, error} ->
          {:error, "Failed to set chat permissions: #{inspect(error)}"}
      end
    end
  end

  defp validate_param(params, key, type \\ :any) do
    case Map.fetch(params, key) do
      {:ok, value} when type == :any and is_binary(value) and value != "" -> {:ok, value}
      {:ok, value} when type == :any and is_integer(value) -> {:ok, value}
      {:ok, value} when type == :map and is_map(value) -> {:ok, value}
      _ -> {:error, "Missing or invalid #{key}"}
    end
  end
end
