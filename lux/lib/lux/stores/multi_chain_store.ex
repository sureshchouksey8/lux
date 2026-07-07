defmodule Lux.Stores.MultiChainStore do
  @moduledoc """
  A durable DETS-based aggregate store for multi-chain data.
  """
  use GenServer

  @table :multi_chain_store

  # Client APIs

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def insert(key, value) do
    GenServer.call(__MODULE__, {:insert, key, value})
  end

  def get(key) do
    case :dets.lookup(@table, key) do
      [{^key, value}] -> {:ok, value}
      [] -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_all() do
    # basic query interface
    case :dets.match_object(@table, :_) do
      results when is_list(results) ->
        Enum.map(results, fn {_k, v} -> v end)
      {:error, _} ->
        []
    end
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    file_path = Keyword.get(opts, :file, ~c"multi_chain_store.dets")
    
    case :dets.open_file(@table, type: :set, file: file_path) do
      {:ok, @table} -> {:ok, %{file: file_path}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:insert, key, value}, _from, state) do
    :dets.insert(@table, {key, value})
    :dets.sync(@table)
    {:reply, :ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :dets.close(@table)
  end
end
