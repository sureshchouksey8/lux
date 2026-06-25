defmodule Lux.Integrations.Telegram.ModeratorTest do
  use UnitAPICase, async: true

  alias Lux.Integrations.Telegram.Moderator

  @chat_id "123456789"
  @user_id 987654
  @message_id 111222

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "moderate_message/3" do
    test "ignores clean message" do
      message = %{
        "message_id" => @message_id,
        "from" => %{"id" => @user_id, "username" => "alice"},
        "text" => "Hello, this is a clean message!"
      }

      assert {:ok, :clean} = Moderator.moderate_message(@chat_id, message)
    end

    test "flags and moderates spam message" do
      message = %{
        "message_id" => @message_id,
        "from" => %{"id" => @user_id, "username" => "spammer123"},
        "text" => "Check out this awesome CASINO website where you make money fast!"
      }

      # We expect two requests: deleteMessage and restrictChatMember
      Req.Test.expect(TelegramClientMock, 2, fn conn ->
        assert conn.method == "POST"
        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        cond do
          String.ends_with?(conn.request_path, "/deleteMessage") ->
            assert decoded["chat_id"] == @chat_id
            assert decoded["message_id"] == @message_id

            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true, "result" => true}))

          String.ends_with?(conn.request_path, "/restrictChatMember") ->
            assert decoded["chat_id"] == @chat_id
            assert decoded["user_id"] == @user_id
            assert decoded["permissions"]["can_send_messages"] == false

            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true, "result" => true}))

          true ->
            flunk("Unexpected endpoint called: #{conn.request_path}")
        end
      end)

      assert {:flagged, %{delete: {:ok, delete_res}, restrict: {:ok, restrict_res}}} =
               Moderator.moderate_message(@chat_id, message)

      assert delete_res.deleted == true
      assert restrict_res.success == true
    end
  end
end
