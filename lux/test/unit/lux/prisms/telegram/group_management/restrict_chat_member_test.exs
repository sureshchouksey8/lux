defmodule Lux.Prisms.Telegram.GroupManagement.RestrictChatMemberTest do
  use UnitAPICase, async: true

  alias Lux.Prisms.Telegram.GroupManagement.RestrictChatMember

  @chat_id 123_456_789
  @user_id 987_654_321
  @permissions %{
    "can_send_messages" => false,
    "can_send_photos" => false
  }
  @agent_ctx %{name: "TestAgent"}

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "handler/2" do
    test "successfully restricts a member with required parameters" do
      Req.Test.expect(TelegramClientMock, fn conn ->
        assert conn.method == "POST"

        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        decoded_body = Jason.decode!(body)
        assert decoded_body["chat_id"] == @chat_id
        assert decoded_body["user_id"] == @user_id
        assert decoded_body["permissions"] == @permissions

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{
          "ok" => true,
          "result" => true
        }))
      end)

      assert {:ok, %{success: true}} =
               RestrictChatMember.handler(
                 %{
                   chat_id: @chat_id,
                   user_id: @user_id,
                   permissions: @permissions,
                   plug: {Req.Test, __MODULE__}
                 },
                 @agent_ctx
               )
    end

    test "validates required parameters" do
      result = RestrictChatMember.handler(%{chat_id: @chat_id, user_id: @user_id}, @agent_ctx)
      assert result == {:error, "Missing or invalid permissions"}
    end
  end

  describe "schema validation" do
    test "validates input schema" do
      prism = RestrictChatMember.view()
      assert prism.input_schema.required == ["chat_id", "user_id", "permissions"]
      assert Map.has_key?(prism.input_schema.properties, :permissions)
    end
  end
end
