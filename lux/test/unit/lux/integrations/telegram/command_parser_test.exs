defmodule Lux.Integrations.Telegram.CommandParserTest do
  use ExUnit.Case, async: true

  alias Lux.Integrations.Telegram.CommandParser

  describe "parse/1" do
    test "correctly parses basic commands" do
      assert {:ok, res} = CommandParser.parse("/start")
      assert res.command == "start"
      assert res.args == []

      assert {:ok, res2} = CommandParser.parse("/help arg1 arg2")
      assert res2.command == "help"
      assert res2.args == ["arg1", "arg2"]
    end

    test "strips bot username suffix" do
      assert {:ok, res} = CommandParser.parse("/start@MyAwesomeBot payload")
      assert res.command == "start"
      assert res.args == ["payload"]
    end

    test "parses flags correctly" do
      assert {:ok, res} = CommandParser.parse("/add --item apple --qty 5")
      assert res.command == "add"
      assert res.flags == %{"item" => "apple", "qty" => "5"}
    end

    test "handles non-commands gracefully" do
      assert {:error, :not_a_command} = CommandParser.parse("hello bot")
      assert {:error, :not_a_command} = CommandParser.parse("")
    end
  end

  describe "extract_deep_link/1" do
    test "extracts payload from start command" do
      assert {:ok, "my_invite_code"} = CommandParser.extract_deep_link("/start my_invite_code")
    end

    test "returns error on missing payload or other command" do
      assert {:error, :no_deep_link} = CommandParser.extract_deep_link("/start")
      assert {:error, :no_deep_link} = CommandParser.extract_deep_link("/help payload")
    end
  end
end
