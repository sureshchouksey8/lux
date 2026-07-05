defmodule Lux.Prisms.Telegram.GroupManagement.UnbanChatMemberTest do
  use UnitAPICase, async: true

  alias Lux.Prisms.Telegram.GroupManagement.UnbanChatMember

  @chat_id 123_456_789
  @user_id 987_654_321
  @agent_ctx %{name: "TestAgent"}

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "handler/2" do
    test "successfully unbans a member with required parameters" do
      Req.Test.expect(TelegramClientMock, fn conn ->
        assert conn.method == "POST"

        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        decoded_body = Jason.decode!(body)
        assert decoded_body["chat_id"] == @chat_id
        assert decoded_body["user_id"] == @user_id

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{
          "ok" => true,
          "result" => true
        }))
      end)

      assert {:ok, %{success: true}} =
               UnbanChatMember.handler(
                 %{
                   chat_id: @chat_id,
                   user_id: @user_id,
                   plug: {Req.Test, __MODULE__}
                 },
                 @agent_ctx
               )
    end

    test "validates required parameters" do
      result = UnbanChatMember.handler(%{user_id: @user_id}, @agent_ctx)
      assert result == {:error, "Missing or invalid chat_id"}
    end
  end

  describe "schema validation" do
    test "validates input schema" do
      prism = UnbanChatMember.view()
      assert prism.input_schema.required == ["chat_id", "user_id"]
      assert Map.has_key?(prism.input_schema.properties, :only_if_banned)
    end
  end
end
