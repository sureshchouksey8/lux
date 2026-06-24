defmodule Lux.Prisms.Twitter.CreateTweet do
  @moduledoc """
  Creates a new tweet on behalf of the authenticated user.
  """

  use Lux.Prism

  alias Lux.Integrations.Twitter.Client

  def schema do
    %{
      type: :object,
      properties: %{
        text: %{
          type: :string,
          description: "Text of the tweet"
        },
        reply_to_tweet_id: %{
          type: :string,
          description: "Optional ID of the tweet to reply to"
        },
        quote_tweet_id: %{
          type: :string,
          description: "Optional ID of the tweet to quote"
        }
      },
      required: ["text"]
    }
  end

  def handler(input, _context) do
    payload = %{"text" => input["text"]}
    
    payload = 
      if reply_id = input["reply_to_tweet_id"] do
        Map.put(payload, "reply", %{"in_reply_to_tweet_id" => reply_id})
      else
        payload
      end
      
    payload = 
      if quote_id = input["quote_tweet_id"] do
        Map.put(payload, "quote_tweet_id", quote_id)
      else
        payload
      end

    case Client.post("/tweets", payload) do
      {:ok, %{status: 201, body: %{"data" => data}}} ->
        {:ok, data}

      {:ok, %{status: status, body: body}} ->
        {:error, "Twitter API error (status #{status}): #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
end
