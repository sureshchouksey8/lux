defmodule Lux.Integration.YouTubeCommunityManagementTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Integration test demonstrating comment management, automated response, sentiment analysis,
  and moderation capabilities for YouTube Community Management.
  """

  alias Lux.Lenses.YouTube.ListCommentThreads
  alias Lux.Prisms.YouTube.ReplyToComment
  alias Lux.Prisms.YouTube.ModerateComment
  alias Lux.Prisms.SentimentAnalysisPrism

  # We mock the YouTube API responses, but we integrate all the Prisms/Lenses together
  alias Lux.Integrations.YouTube.Client, as: YouTubeClient

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  test "end-to-end community management flow: fetch comments, analyze sentiment, reply to positive, moderate negative" do
    # 1. Fetch Comments
    Req.Test.expect(YouTubeClient, fn conn ->
      assert conn.method == "GET"
      assert conn.request_path == "/youtube/v3/commentThreads"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(%{
        "items" => [
          %{
            "id" => "comment_pos",
            "snippet" => %{
              "videoId" => "vid1",
              "topLevelComment" => %{
                "snippet" => %{
                  "textDisplay" => "This video is amazing and very helpful!",
                  "textOriginal" => "This video is amazing and very helpful!",
                  "authorDisplayName" => "HappyUser"
                }
              }
            }
          },
          %{
            "id" => "comment_neg",
            "snippet" => %{
              "videoId" => "vid1",
              "topLevelComment" => %{
                "snippet" => %{
                  "textDisplay" => "This is terrible, I hate this spam.",
                  "textOriginal" => "This is terrible, I hate this spam.",
                  "authorDisplayName" => "AngryUser"
                }
              }
            }
          }
        ]
      }))
    end)

    assert {:ok, %{comments: comments}} = ListCommentThreads.focus(%{
      video_id: "vid1",
      plug: YouTubeClient
    })

    assert length(comments) == 2

    # 2. Process Comments (Sentiment Analysis, Reply, Moderate)
    for comment <- comments do
      # Analyze sentiment
      assert {:ok, sentiment_result} = SentimentAnalysisPrism.run(%{
        text: comment.text_original,
        language: "en"
      })

      sentiment = sentiment_result["sentiment"] || sentiment_result[:sentiment]

      # Depending on sentiment, we take different actions
      case sentiment do
        "positive" ->
          # Reply to positive comment
          Req.Test.expect(YouTubeClient, fn conn ->
            assert conn.method == "POST"
            assert conn.request_path == "/youtube/v3/comments"
            {:ok, body, conn} = Plug.Conn.read_body(conn)
            json_body = Jason.decode!(body)
            assert json_body["snippet"]["parentId"] == comment.id

            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(200, Jason.encode!(%{
              "id" => "reply_" <> comment.id,
              "snippet" => %{"textOriginal" => "Thank you for the kind words!"}
            }))
          end)

          assert {:ok, %{replied: true}} = ReplyToComment.handler(%{
            parent_id: comment.id,
            text: "Thank you for the kind words!",
            plug: YouTubeClient
          }, %{name: "CommunityManager"})

        "negative" ->
          # Moderate negative/spam comment (e.g. reject it)
          Req.Test.expect(YouTubeClient, fn conn ->
            assert conn.method == "POST"
            assert conn.request_path == "/youtube/v3/comments/setModerationStatus"
            assert conn.params["id"] == comment.id
            assert conn.params["moderationStatus"] == "rejected"

            conn
            |> Plug.Conn.put_resp_content_type("application/json")
            |> Plug.Conn.send_resp(204, "")
          end)

          assert {:ok, %{moderated: true}} = ModerateComment.handler(%{
            comment_id: comment.id,
            moderation_status: "rejected",
            ban_author: false,
            plug: YouTubeClient
          }, %{name: "CommunityManager"})

        _ ->
          :ok
      end
    end
  end
end
