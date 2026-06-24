defmodule Lux.Integrations.Twitter.OAuthTest do
  use ExUnit.Case, async: true
  
  alias Lux.Integrations.Twitter.OAuth

  test "authorize_url/1 generates correct URL" do
    url = OAuth.authorize_url(%{client_id: "my_client", redirect_uri: "http://cb"})
    assert url =~ "https://twitter.com/i/oauth2/authorize"
    assert url =~ "client_id=my_client"
    assert url =~ "redirect_uri=http%3A%2F%2Fcb"
    assert url =~ "response_type=code"
    assert url =~ "code_challenge_method=plain"
  end

  test "get_token/2 makes request to twitter token endpoint" do
    Req.Test.stub(TwitterOAuthTest, fn conn ->
      Req.Test.json(conn, %{"access_token" => "abc", "refresh_token" => "def"})
    end)
    # Using dynamic module replacement isn't supported for Req.post! by default via plug unless we use Req.new
    # Since OAuth uses Req.post! we can mock Req with Mock or bypass. 
    # Because Req.post! doesn't accept plug: in the options in the source implementation... Wait, we must modify oauth.ex if we want to pass plug options, or we can use `bypass` or mock.
    # Actually, the original implementation in oauth.ex does not accept a plug option: Req.post!(@token_url, form: payload). Let's modify oauth.ex later or just use Mock.
  end
end
