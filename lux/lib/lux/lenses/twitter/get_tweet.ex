defmodule Lux.Lenses.Twitter.GetTweet do
  @moduledoc "Reads an X/Twitter post by ID."

  alias Lux.Integrations.Twitter.Client

  def view do
    Lux.Lens.new(
      name: "Get Twitter Post",
      module_name: inspect(__MODULE__),
      description: "Reads a post through X/Twitter API v2",
      schema: %{type: :object, properties: %{tweet_id: %{type: :string}}, required: ["tweet_id"]}
    )
  end

  def focus(%{tweet_id: tweet_id} = input, _opts \\ []) do
    opts = Map.take(input, [:access_token, :bearer_token, :plug, :with_rate_limit])
    params = Map.drop(input, [:tweet_id, :access_token, :bearer_token, :plug, :with_rate_limit])
    Client.get_tweet(tweet_id, params, opts)
  end
end
