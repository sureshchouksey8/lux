defmodule Lux.Prisms.Telegram.GroupManagement.SetChatPermissionsTest do
  use UnitAPICase, async: true

  alias Lux.Prisms.Telegram.GroupManagement.SetChatPermissions

  @chat_id 123_456_789
  @permissions %{
    "can_send_messages" => false
  }
  @agent_ctx %{name: "TestAgent"}

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "handler/2" do
    test "successfully sets chat permissions" do
      Req.Test.expect(TelegramClientMock, fn conn ->
        assert conn.method == "POST"

        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        decoded_body = Jason.decode!(body)
        assert decoded_body["chat_id"] == @chat_id
        assert decoded_body["permissions"] == @permissions

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{
          "ok" => true,
          "result" => true
        }))
      end)

      assert {:ok, %{success: true}} =
               SetChatPermissions.handler(
                 %{
                   chat_id: @chat_id,
                   permissions: @permissions,
                   plug: {Req.Test, __MODULE__}
                 },
                 @agent_ctx
               )
    end
  end
end
