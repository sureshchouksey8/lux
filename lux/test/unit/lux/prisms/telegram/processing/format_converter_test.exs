defmodule Lux.Prisms.Telegram.Processing.FormatConverterTest do
  use ExUnit.Case, async: true
  
  alias Lux.Prisms.Telegram.Processing.FormatConverter

  describe "handler/2" do
    test "formats text as markdown" do
      params = %{
        text: "Hello world",
        format: "markdown",
        entities: [
          %{type: "bold", offset: 0, length: 5},
          %{type: "italic", offset: 6, length: 5}
        ]
      }
      
      assert {:ok, %{formatted_text: "**Hello** _world_"}} = FormatConverter.handler(params, %{})
    end
    
    test "formats text as html" do
      params = %{
        text: "Hello world",
        format: "html",
        entities: [
          %{type: "bold", offset: 0, length: 5},
          %{type: "italic", offset: 6, length: 5}
        ]
      }
      
      assert {:ok, %{formatted_text: "<b>Hello</b> <i>world</i>"}} = FormatConverter.handler(params, %{})
    end
    
    test "handles missing entities" do
      params = %{
        text: "Hello world",
        format: "markdown"
      }
      
      assert {:ok, %{formatted_text: "Hello world"}} = FormatConverter.handler(params, %{})
    end
    
    test "handles text with emoji using correct utf16 offsets" do
      # In UTF-16, an emoji might take 2 code units.
      params = %{
        text: "Hi 🚀 test",
        format: "html",
        entities: [
          %{type: "bold", offset: 6, length: 4}
        ]
      }
      
      assert {:ok, %{formatted_text: "Hi 🚀 <b>test</b>"}} = FormatConverter.handler(params, %{})
    end
    
    test "handles missing text or format" do
      assert {:error, _} = FormatConverter.handler(%{text: "hi"}, %{})
      assert {:error, _} = FormatConverter.handler(%{format: "html"}, %{})
    end
  end
end
