defmodule Lux.Prisms.Twitter.CreateTweetTest do
  use ExUnit.Case, async: true

  alias Lux.Prisms.Twitter.CreateTweet

  setup do
    Application.put_env(:lux, :env, :test)
    Application.put_env(:lux, :twitter_bearer_token, "test_token")
    :ok
  end

  test "creates a tweet successfully" do
    Req.Test.stub(Lux.Integrations.Twitter, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/2/tweets"
      
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      decoded = Jason.decode!(body)
      assert decoded["text"] == "Hello from Lux"

      Plug.Conn.send_resp(conn, 201, Jason.encode!(%{"data" => %{"id" => "123", "text" => "Hello from Lux"}}))
    end)

    assert {:ok, %{"id" => "123", "text" => "Hello from Lux"}} = 
      CreateTweet.handler(%{"text" => "Hello from Lux"}, %{})
  end

  test "creates a reply tweet" do
    Req.Test.stub(Lux.Integrations.Twitter, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      decoded = Jason.decode!(body)
      assert decoded["text"] == "Reply!"
      assert decoded["reply"]["in_reply_to_tweet_id"] == "456"

      Plug.Conn.send_resp(conn, 201, Jason.encode!(%{"data" => %{"id" => "124"}}))
    end)

    assert {:ok, %{"id" => "124"}} = 
      CreateTweet.handler(%{"text" => "Reply!", "reply_to_tweet_id" => "456"}, %{})
  end

  test "handles error response" do
    Req.Test.stub(Lux.Integrations.Twitter, fn conn ->
      Plug.Conn.send_resp(conn, 400, Jason.encode!(%{"errors" => ["Bad Request"]}))
    end)

    assert {:error, msg} = CreateTweet.handler(%{"text" => "Fail"}, %{})
    assert msg =~ "Twitter API error"
  end
end
