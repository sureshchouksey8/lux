defmodule Lux.Prisms.Telegram.Processing.CallbackQueryParserTest do
  use ExUnit.Case, async: true
  
  alias Lux.Prisms.Telegram.Processing.CallbackQueryParser

  describe "handler/2" do
    test "parses a simple callback query" do
      params = %{
        callback_query: %{
          "id" => "123",
          "from" => %{"id" => 456},
          "data" => "like"
        }
      }
      
      assert {:ok, result} = CallbackQueryParser.handler(params, %{})
      assert result.id == "123"
      assert result.from_id == 456
      assert result.action == "like"
      assert result.params == %{}
    end
    
    test "parses a callback query with params" do
      params = %{
        callback_query: %{
          "id" => "123",
          "from" => %{"id" => 456},
          "data" => "buy:item=apple:qty=5"
        }
      }
      
      assert {:ok, result} = CallbackQueryParser.handler(params, %{})
      assert result.action == "buy"
      assert result.params == %{"item" => "apple", "qty" => "5"}
    end
    
    test "handles flag params" do
      params = %{
        callback_query: %{
          "id" => "123",
          "from" => %{"id" => 456},
          "data" => "settings:notifications:dark_mode=on"
        }
      }
      
      assert {:ok, result} = CallbackQueryParser.handler(params, %{})
      assert result.action == "settings"
      assert result.params == %{"notifications" => true, "dark_mode" => "on"}
    end
    
    test "handles missing callback_query" do
      assert {:error, _} = CallbackQueryParser.handler(%{}, %{})
    end
  end
end
