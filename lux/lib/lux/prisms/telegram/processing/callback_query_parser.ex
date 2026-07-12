defmodule Lux.Prisms.Telegram.Processing.CallbackQueryParser do
  @moduledoc """
  A prism for parsing Telegram callback queries.
  """

  use Lux.Prism,
    name: "Telegram Callback Query Parser",
    description: "Parses Telegram callback queries to extract action and parameters",
    input_schema: %{
      type: :object,
      properties: %{
        callback_query: %{
          type: :object,
          description: "Telegram callback query object"
        }
      },
      required: ["callback_query"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        id: %{type: :string},
        from_id: %{type: :integer},
        data: %{type: :string},
        action: %{type: :string},
        params: %{type: :object}
      },
      required: ["id", "from_id"]
    }

  def handler(%{callback_query: callback_query}, _agent) when is_map(callback_query) do
    callback_query = stringify_keys(callback_query)
    
    id = callback_query["id"]
    from_id = get_in(callback_query, ["from", "id"])
    data = callback_query["data"] || ""
    
    # Simple query parsing assuming format: "action:param1=value1:param2=value2"
    # or just "action"
    parts = String.split(data, ":")
    action = List.first(parts) || ""
    
    params = 
      parts
      |> Enum.drop(1)
      |> Enum.reduce(%{}, fn part, acc ->
        case String.split(part, "=", parts: 2) do
          [k, v] -> Map.put(acc, k, v)
          [k] -> Map.put(acc, k, true)
          _ -> acc
        end
      end)
      
    {:ok, %{
      id: id,
      from_id: from_id,
      data: data,
      action: action,
      params: params
    }}
  end
  
  def handler(%{"callback_query" => cq}, agent) when is_map(cq) do
    handler(%{callback_query: cq}, agent)
  end
  
  def handler(_params, _agent) do
    {:error, "Missing required parameter: callback_query"}
  end
  
  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
