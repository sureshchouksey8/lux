defmodule Lux.Integrations.Telegram.CommandParser do
  @moduledoc """
  A utility module to parse commands and extract arguments from Telegram messages.
  Supports basic commands, deep links (from `/start <payload>`), and options/flags.
  """

  @doc """
  Parses a command from message text.

  ## Examples
      iex> parse("/start hello_world")
      {:ok, %{command: "start", args: ["hello_world"], raw_args: "hello_world", flags: %{}}}

      iex> parse("/add --item apples --qty 5")
      {:ok, %{command: "add", args: [], raw_args: "--item apples --qty 5", flags: %{"item" => "apples", "qty" => "5"}}}

      iex> parse("Not a command")
      {:error, :not_a_command}
  """
  def parse(text) when is_binary(text) do
    trimmed = String.trim(text)

    if String.starts_with?(trimmed, "/") do
      # Extract command and arguments
      [raw_cmd | rest] = String.split(trimmed, ~r/\s+/, parts: 2)
      
      # Strip leading slash and potential bot username suffix (e.g. /start@MyBot -> start)
      command = 
        raw_cmd 
        |> String.slice(1..-1//1) 
        |> String.split("@") 
        |> List.first()

      raw_args = List.first(rest) || ""
      args = if raw_args == "", do: [], else: String.split(raw_args, ~r/\s+/)

      # Parse flags if any (e.g. --key value or -k value)
      flags = parse_flags(args)

      {:ok, %{
        command: command,
        args: args,
        raw_args: raw_args,
        flags: flags
      }}
    else
      {:error, :not_a_command}
    end
  end

  def parse(_), do: {:error, :not_a_command}

  @doc """
  Extracts deep link payload from a start command.
  If text is `/start payload`, returns `{:ok, "payload"}`.
  """
  def extract_deep_link(text) do
    case parse(text) do
      {:ok, %{command: "start", args: [payload | _]}} -> {:ok, payload}
      _ -> {:error, :no_deep_link}
    end
  end

  # Helper to parse --key value or -k value flags
  defp parse_flags(args) do
    parse_flags(args, %{})
  end

  defp parse_flags([], acc), do: acc
  defp parse_flags([flag, val | rest], acc) when String.starts_with?(flag, "-") do
    key = String.replace(flag, ~r/^-+/, "")
    parse_flags(rest, Map.put(acc, key, val))
  end
  defp parse_flags([_ | rest], acc), do: parse_flags(rest, acc)
end
