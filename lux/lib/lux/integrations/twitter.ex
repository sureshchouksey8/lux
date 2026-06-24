defmodule Lux.Integrations.Twitter do
  @moduledoc """
  Common settings and configuration for Twitter API v2 integration.
  """

  @doc """
  Returns the base URL for Twitter API v2.
  """
  def base_url, do: "https://api.twitter.com/2"

  @doc """
  Returns the base URL for Twitter Media API (v1.1).
  """
  def media_base_url, do: "https://upload.twitter.com/1.1"

  @doc """
  Builds standard request headers for API v2 requests using a bearer token or OAuth 2.0 access token.
  """
  def headers(token) do
    [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]
  end

  @doc """
  Builds OAuth 1.0a headers for Twitter API (required for some media endpoints if not using OAuth 2.0).
  In a real scenario, this would generate the OAuth signature.
  """
  def oauth1_headers(_method, _url, _params) do
    # Placeholder for OAuth 1.0a signature generation
    []
  end
end
