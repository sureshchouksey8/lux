defmodule Lux.Integrations.Twitter.Client do
  @moduledoc """
  Core Twitter API v2 integration client.
  Handles OAuth 2.0 / Bearer token authentication, rate limits, and common request logic.
  """

  @base_url "https://api.twitter.com/2"

  def base_req do
    req = 
      Req.new(base_url: @base_url)
      |> Req.Request.append_request_steps(
        auth: &auth_step/1,
        rate_limit: &rate_limit_step/1
      )

    if Application.get_env(:lux, :env) == :test do
      Req.Request.append_request_steps(req, plug: {Req.Test, Lux.Integrations.Twitter})
    else
      req
    end
  end

  defp auth_step(request) do
    # Prefer bearer token for API v2 if available
    token = Application.get_env(:lux, :twitter_bearer_token) || System.get_env("TWITTER_BEARER_TOKEN")
    
    if token do
      Req.Request.put_header(request, "authorization", "Bearer #{token}")
    else
      request
    end
  end

  defp rate_limit_step(request) do
    # Basic rate limit tracking via response headers could be implemented here
    # For now, it passes through. Twitter v2 headers: x-rate-limit-remaining, etc.
    request
  end

  def get(path, params \\ []) do
    base_req()
    |> Req.get(url: path, params: params)
  end

  def post(path, body) do
    base_req()
    |> Req.post(url: path, json: body)
  end

  def delete(path) do
    base_req()
    |> Req.delete(url: path)
  end
end
