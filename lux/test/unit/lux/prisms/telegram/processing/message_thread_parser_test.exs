defmodule Lux.Prisms.Telegram.Processing.MessageThreadParserTest do
  use ExUnit.Case, async: true
  
  alias Lux.Prisms.Telegram.Processing.MessageThreadParser

  describe "handler/2" do
    test "parses a regular topic message" do
      params = %{
        message: %{
          "is_topic_message" => true,
          "message_thread_id" => 123
        }
      }
      
      assert {:ok, result} = MessageThreadParser.handler(params, %{})
      assert result.is_topic_message == true
      assert result.message_thread_id == 123
      assert result.is_topic_action == false
    end
    
    test "parses a topic action message" do
      params = %{
        message: %{
          "forum_topic_created" => %{"name" => "General"},
          "message_thread_id" => 123
        }
      }
      
      assert {:ok, result} = MessageThreadParser.handler(params, %{})
      assert result.is_topic_message == true
      assert result.message_thread_id == 123
      assert result.is_topic_action == true
      assert result.action_type == "created"
    end
    
    test "parses a non-topic message" do
      params = %{
        message: %{
          "text" => "hello"
        }
      }
      
      assert {:ok, result} = MessageThreadParser.handler(params, %{})
      assert result.is_topic_message == false
      assert result.message_thread_id == nil
      assert result.is_topic_action == false
      assert result.action_type == nil
    end
    
    test "handles missing message" do
      assert {:error, _} = MessageThreadParser.handler(%{}, %{})
    end
  end
end
