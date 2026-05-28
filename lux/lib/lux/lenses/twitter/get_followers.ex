defmodule Lux.Lenses.Twitter.GetFollowers do
  @moduledoc "Reads followers for an X/Twitter user."

  alias Lux.Integrations.Twitter.Client

  def view do
    Lux.Lens.new(
      name: "Get Twitter Followers",
      module_name: inspect(__MODULE__),
      description: "Reads followers for a user through X/Twitter API v2",
      schema: %{
        type: :object,
        properties: %{
          user_id: %{type: :string},
          user_fields: %{type: :array, items: %{type: :string}},
          max_results: %{type: :integer},
          pagination_token: %{type: :string}
        },
        required: ["user_id"]
      }
    )
  end

  def focus(input, opts \\ [])

  def focus(%{user_id: user_id} = input, _opts) do
    opts = Map.take(input, [:access_token, :bearer_token, :plug, :with_rate_limit])
    params = Map.drop(input, [:user_id, :access_token, :bearer_token, :plug, :with_rate_limit])
    Client.get_followers(user_id, params, opts)
  end

  def focus(_input, _opts), do: {:error, "Missing user_id"}
end
