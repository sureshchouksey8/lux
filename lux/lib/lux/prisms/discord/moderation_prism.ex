defmodule Lux.Prisms.Discord.ModerationPrism do
  @moduledoc """
  A prism for managing Discord moderation actions.
  Supports user timeouts, bans, unbans, and kick operations.
  """
  use Lux.Prism,
    name: "Discord Moderation",
    description: "Handles Discord server moderation tasks such as ban, unban, timeout, and kick.",
    input_schema: %{
      type: :object,
      properties: %{
        action: %{
          type: :string,
          enum: ["timeout", "ban", "unban", "kick"],
          description: "The moderation action to perform."
        },
        guild_id: %{
          type: :string,
          description: "The guild ID."
        },
        user_id: %{
          type: :string,
          description: "The user ID to moderate."
        },
        communication_disabled_until: %{
          type: :string,
          description: "ISO8601 timestamp for timeout (for timeout action, or null to remove)."
        },
        delete_message_days: %{
          type: :integer,
          description: "Number of days to delete messages (for ban)."
        },
        reason: %{
          type: :string,
          description: "Audit log reason."
        }
      },
      required: ["action", "guild_id", "user_id"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        status: %{
          type: :string,
          description: "Status of the operation."
        }
      },
      required: ["status"]
    }

  alias Lux.Integrations.Discord.Client

  def handler(params, _ctx) do
    action = Map.fetch!(params, :action)
    guild_id = Map.fetch!(params, :guild_id)
    user_id = Map.fetch!(params, :user_id)

    case action do
      "timeout" -> timeout_user(guild_id, user_id, params)
      "ban" -> ban_user(guild_id, user_id, params)
      "unban" -> unban_user(guild_id, user_id)
      "kick" -> kick_user(guild_id, user_id)
      _ -> {:error, "Invalid action"}
    end
  end

  defp timeout_user(guild_id, user_id, params) do
    payload = %{communication_disabled_until: Map.get(params, :communication_disabled_until)}

    with_retry(fn ->
      Client.request(:patch, "/guilds/#{guild_id}/members/#{user_id}", %{json: payload})
    end)
    |> format_response(%{})
  end

  defp ban_user(guild_id, user_id, params) do
    payload = Map.take(params, [:delete_message_days])

    opts = %{json: payload}
    opts = if Map.has_key?(params, :reason), do: Map.put(opts, :headers, [{"X-Audit-Log-Reason", params.reason}]), else: opts

    with_retry(fn ->
      Client.request(:put, "/guilds/#{guild_id}/bans/#{user_id}", opts)
    end)
    |> format_response(%{})
  end

  defp unban_user(guild_id, user_id) do
    with_retry(fn ->
      Client.request(:delete, "/guilds/#{guild_id}/bans/#{user_id}")
    end)
    |> format_response(%{})
  end

  defp kick_user(guild_id, user_id) do
    with_retry(fn ->
      Client.request(:delete, "/guilds/#{guild_id}/members/#{user_id}")
    end)
    |> format_response(%{})
  end

  defp format_response({:ok, body}) do
    body = if body == "", do: %{}, else: body
    {:ok, %{status: "success", data: body}}
  end

  defp format_response({:ok, _body}, default) do
    {:ok, %{status: "success", data: default}}
  end

  defp format_response({:error, reason}), do: {:error, reason}

  defp with_retry(func, retries \\ 3) do
    case func.() do
      {:error, {429, _msg}} when retries > 0 ->
        unless Application.get_env(:lux, :env) == :test do
          Process.sleep(100)
        end
        with_retry(func, retries - 1)

      other ->
        other
    end
  end
end
