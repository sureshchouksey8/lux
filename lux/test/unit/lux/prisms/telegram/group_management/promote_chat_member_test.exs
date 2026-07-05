defmodule Lux.Prisms.Telegram.GroupManagement.PromoteChatMemberTest do
  use UnitAPICase, async: true

  alias Lux.Prisms.Telegram.GroupManagement.PromoteChatMember

  @chat_id 123_456_789
  @user_id 987_654_321
  @agent_ctx %{name: "TestAgent"}

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "handler/2" do
    test "successfully promotes a member" do
      Req.Test.expect(TelegramClientMock, fn conn ->
        assert conn.method == "POST"

        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        decoded_body = Jason.decode!(body)
        assert decoded_body["chat_id"] == @chat_id
        assert decoded_body["user_id"] == @user_id
        assert decoded_body["can_manage_chat"] == true

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{
          "ok" => true,
          "result" => true
        }))
      end)

      assert {:ok, %{success: true}} =
               PromoteChatMember.handler(
                 %{
                   chat_id: @chat_id,
                   user_id: @user_id,
                   can_manage_chat: true,
                   plug: {Req.Test, __MODULE__}
                 },
                 @agent_ctx
               )
    end
  end
end
