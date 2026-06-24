defmodule Lux.Prisms.Twitter.DeleteTweet do
  @moduledoc """
  Deletes a tweet by ID.
  """

  use Lux.Prism

  alias Lux.Integrations.Twitter.Client

  def schema do
    %{
      type: :object,
      properties: %{
        tweet_id: %{
          type: :string,
          description: "ID of the tweet to delete"
        }
      },
      required: ["tweet_id"]
    }
  end

  def handler(%{"tweet_id" => tweet_id}, _context) do
    case Client.delete("/tweets/#{tweet_id}") do
      {:ok, %{status: 200, body: %{"data" => %{"deleted" => true}}}} ->
        {:ok, %{"deleted" => true}}

      {:ok, %{status: status, body: body}} ->
        {:error, "Twitter API error (status #{status}): #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
end
