defmodule Lux.Prisms.Twitter.TweetsTest do
  use UnitAPICase, async: true

  alias Lux.Prisms.Twitter.Tweets.CreateThread
  alias Lux.Prisms.Twitter.Tweets.CreateTweet
  alias Lux.Prisms.Twitter.Tweets.DeleteTweet

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  test "create tweet prism passes agent input to the Twitter client" do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/2/tweets"

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{"text" => "hello"}

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(201, Jason.encode!(%{"data" => %{"id" => "tweet-1"}}))
    end)

    assert {:ok, %{"data" => %{"id" => "tweet-1"}}} =
             CreateTweet.handler(%{text: "hello", access_token: "access-1", plug: {Req.Test, __MODULE__}}, %{})
  end

  test "delete tweet prism validates required input" do
    assert {:error, "Missing tweet_id"} = DeleteTweet.handler(%{}, %{})
  end

  test "thread prism creates replies in order" do
    Req.Test.expect(__MODULE__, 2, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      json = Jason.decode!(body)

      id =
        if json["text"] == "one" do
          "tweet-1"
        else
          assert json["reply"]["in_reply_to_tweet_id"] == "tweet-1"
          "tweet-2"
        end

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(201, Jason.encode!(%{"data" => %{"id" => id}}))
    end)

    assert {:ok, [%{"data" => %{"id" => "tweet-1"}}, %{"data" => %{"id" => "tweet-2"}}]} =
             CreateThread.handler(%{texts: ["one", "two"], access_token: "access-1", plug: {Req.Test, __MODULE__}}, %{})
  end
end
