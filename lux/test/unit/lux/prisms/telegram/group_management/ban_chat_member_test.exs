defmodule Lux.Prisms.Telegram.GroupManagement.BanChatMemberTest do
  use UnitAPICase, async: true

  alias Lux.Prisms.Telegram.GroupManagement.BanChatMember

  @chat_id 123_456_789
  @user_id 987_654_321
  @agent_ctx %{name: "TestAgent"}

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "handler/2" do
    test "successfully bans a member with required parameters" do
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
               BanChatMember.handler(
                 %{
                   chat_id: @chat_id,
                   user_id: @user_id,
                   plug: {Req.Test, __MODULE__}
                 },
                 @agent_ctx
               )
    end

    test "successfully bans a member with optional parameters" do
      Req.Test.expect(TelegramClientMock, fn conn ->
        assert conn.method == "POST"

        {:ok, body, _conn} = Plug.Conn.read_body(conn)
        decoded_body = Jason.decode!(body)
        assert decoded_body["chat_id"] == @chat_id
        assert decoded_body["user_id"] == @user_id
        assert decoded_body["until_date"] == 1_700_000_000
        assert decoded_body["revoke_messages"] == true

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{
          "ok" => true,
          "result" => true
        }))
      end)

      assert {:ok, %{success: true}} =
               BanChatMember.handler(
                 %{
                   chat_id: @chat_id,
                   user_id: @user_id,
                   until_date: 1_700_000_000,
                   revoke_messages: true,
                   plug: {Req.Test, __MODULE__}
                 },
                 @agent_ctx
               )
    end

    test "validates required parameters" do
      result = BanChatMember.handler(%{user_id: @user_id}, @agent_ctx)
      assert result == {:error, "Missing or invalid chat_id"}

      result = BanChatMember.handler(%{chat_id: @chat_id}, @agent_ctx)
      assert result == {:error, "Missing or invalid user_id"}
    end

    test "handles Telegram API error" do
      Req.Test.expect(TelegramClientMock, fn conn ->
        assert conn.method == "POST"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(400, Jason.encode!(%{
          "ok" => false,
          "description" => "Bad Request: user is an administrator of the chat"
        }))
      end)

      assert {:error, "Failed to ban chat member: Bad Request: user is an administrator of the chat (HTTP 400)"} =
               BanChatMember.handler(
                 %{
                   chat_id: @chat_id,
                   user_id: @user_id,
                   plug: {Req.Test, __MODULE__}
                 },
                 @agent_ctx
               )
    end
  end

  describe "schema validation" do
    test "validates input schema" do
      prism = BanChatMember.view()
      assert prism.input_schema.required == ["chat_id", "user_id"]
      assert Map.has_key?(prism.input_schema.properties, :chat_id)
      assert Map.has_key?(prism.input_schema.properties, :user_id)
      assert Map.has_key?(prism.input_schema.properties, :until_date)
      assert Map.has_key?(prism.input_schema.properties, :revoke_messages)
    end

    test "validates output schema" do
      prism = BanChatMember.view()
      assert prism.output_schema.required == ["success"]
      assert Map.has_key?(prism.output_schema.properties, :success)
    end
  end
end
