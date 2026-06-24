defmodule Lux.Prisms.Twitter.CreateThread do
  @moduledoc """
  Creates a thread of tweets.
  """

  use Lux.Prism

  alias Lux.Integrations.Twitter.Client

  def schema do
    %{
      type: :object,
      properties: %{
        tweets: %{
          type: :array,
          description: "List of tweet texts to create a thread",
          items: %{type: :string}
        }
      },
      required: ["tweets"]
    }
  end

  def handler(%{"tweets" => [first_tweet | rest_tweets]}, _context) do
    # Post first tweet
    case Client.post("/tweets", %{"text" => first_tweet}) do
      {:ok, %{status: 201, body: %{"data" => %{"id" => id} = first_data}}} ->
        # Post rest of tweets
        thread_data = 
          Enum.reduce_while(rest_tweets, [first_data], fn text, acc ->
            last_id = hd(acc)["id"]
            payload = %{
              "text" => text,
              "reply" => %{"in_reply_to_tweet_id" => last_id}
            }
            
            case Client.post("/tweets", payload) do
              {:ok, %{status: 201, body: %{"data" => data}}} ->
                {:cont, [data | acc]}
              _error ->
                {:halt, acc} # Halt if a tweet fails, returning successful ones so far
            end
          end)
          
        {:ok, Enum.reverse(thread_data)}

      {:ok, %{status: status, body: body}} ->
        {:error, "Twitter API error (status #{status}): #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  def handler(%{"tweets" => []}, _context) do
    {:error, "Cannot create an empty thread"}
  end
end
