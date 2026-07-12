defmodule Lux.Prisms.Telegram.Processing.ReplyParserTest do
  use ExUnit.Case, async: true
  
  alias Lux.Prisms.Telegram.Processing.ReplyParser

  describe "handler/2" do
    test "parses a reply message" do
      params = %{
        message: %{
          "reply_to_message" => %{
            "message_id" => 123,
            "from" => %{"id" => 456},
            "text" => "original message"
          }
        }
      }
      
      assert {:ok, result} = ReplyParser.handler(params, %{})
      assert result.is_reply == true
      assert result.replied_message_id == 123
      assert result.replied_user_id == 456
      assert result.replied_text == "original message"
    end
    
    test "parses a reply message with caption" do
      params = %{
        message: %{
          "reply_to_message" => %{
            "message_id" => 124,
            "from" => %{"id" => 456},
            "caption" => "a photo"
          }
        }
      }
      
      assert {:ok, result} = ReplyParser.handler(params, %{})
      assert result.is_reply == true
      assert result.replied_message_id == 124
      assert result.replied_text == "a photo"
    end
    
    test "parses a non-reply message" do
      params = %{
        message: %{
          "text" => "hello"
        }
      }
      
      assert {:ok, result} = ReplyParser.handler(params, %{})
      assert result.is_reply == false
      assert result.replied_message_id == nil
      assert result.replied_user_id == nil
      assert result.replied_text == nil
    end
    
    test "handles missing message" do
      assert {:error, _} = ReplyParser.handler(%{}, %{})
    end
  end
end
