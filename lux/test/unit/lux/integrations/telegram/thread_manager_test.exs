defmodule Lux.Integrations.Telegram.ThreadManagerTest do
  use ExUnit.Case, async: true

  alias Lux.Integrations.Telegram.ThreadManager

  setup do
    {:ok, manager} = ThreadManager.start_link()
    {:ok, manager: manager}
  end

  describe "message threading" do
    test "adds single message and returns thread with only that message", %{manager: manager} do
      msg = %{"message_id" => 1, "text" => "First"}
      assert :ok = ThreadManager.add_message(manager, "chat123", msg)

      assert [msg] == ThreadManager.get_thread(manager, "chat123", 1)
    end

    test "links replies to the parent thread", %{manager: manager} do
      msg1 = %{"message_id" => 100, "text" => "Root message"}
      msg2 = %{
        "message_id" => 101,
        "text" => "Reply 1",
        "reply_to_message" => %{"message_id" => 100}
      }
      msg3 = %{
        "message_id" => 102,
        "text" => "Reply 2 (replying to Reply 1)",
        "reply_to_message" => %{"message_id" => 101}
      }

      assert :ok = ThreadManager.add_message(manager, "chat123", msg1)
      assert :ok = ThreadManager.add_message(manager, "chat123", msg2)
      assert :ok = ThreadManager.add_message(manager, "chat123", msg3)

      # Querying thread by root_id
      thread = ThreadManager.get_thread(manager, "chat123", 100)
      assert length(thread) == 3
      assert Enum.map(thread, & &1["message_id"]) == [100, 101, 102]

      # Querying thread by a child reply_id should also resolve back to the root and return the whole thread
      thread_by_child = ThreadManager.get_thread(manager, "chat123", 102)
      assert length(thread_by_child) == 3
      assert Enum.map(thread_by_child, & &1["message_id"]) == [100, 101, 102]
    end
  end

  describe "callback query management" do
    test "registers callback queries", %{manager: manager} do
      query = %{"id" => "q123", "data" => "click_button"}
      assert :ok = ThreadManager.add_callback(manager, query)

      assert [query] == ThreadManager.get_callbacks(manager)
    end
  end
end
