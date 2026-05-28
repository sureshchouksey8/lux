defmodule Lux.Lenses.Twitter.SearchRecent do
  @moduledoc "Searches recent X/Twitter posts."

  alias Lux.Integrations.Twitter.Client

  def view do
    Lux.Lens.new(
      name: "Search Recent Twitter Posts",
      module_name: inspect(__MODULE__),
      description: "Searches recent posts through X/Twitter API v2",
      schema: %{type: :object, properties: %{query: %{type: :string}}, required: ["query"]}
    )
  end

  def focus(%{query: query} = input, _opts \\ []) do
    opts = Map.take(input, [:access_token, :bearer_token, :plug, :with_rate_limit])
    params = Map.drop(input, [:query, :access_token, :bearer_token, :plug, :with_rate_limit])
    Client.search_recent(query, params, opts)
  end
end
