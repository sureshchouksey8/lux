defmodule Lux.Prisms.Telegram.Processing.FormatConverter do
  @moduledoc """
  A prism for formatting Telegram message entities into Markdown or HTML.
  """

  use Lux.Prism,
    name: "Telegram Format Converter",
    description: "Converts Telegram message text and entities into Markdown or HTML",
    input_schema: %{
      type: :object,
      properties: %{
        text: %{type: :string},
        entities: %{
          type: :array,
          items: %{
            type: :object,
            properties: %{
              type: %{type: :string},
              offset: %{type: :integer},
              length: %{type: :integer},
              url: %{type: :string}
            }
          }
        },
        format: %{
          type: :string,
          enum: ["markdown", "html"],
          description: "Target format"
        }
      },
      required: ["text", "format"]
    },
    output_schema: %{
      type: :object,
      properties: %{
        formatted_text: %{type: :string}
      },
      required: ["formatted_text"]
    }

  def handler(%{text: text, format: format} = params, _agent) when is_binary(text) do
    entities = Map.get(params, :entities, []) || Map.get(params, "entities", [])
    
    formatted_text = 
      case format do
        "markdown" -> format_markdown(text, entities)
        "html" -> format_html(text, entities)
        _ -> text
      end
      
    {:ok, %{formatted_text: formatted_text}}
  end
  
  def handler(_params, _agent) do
    {:error, "Missing required parameters text or format"}
  end

  defp format_markdown(text, []) do
    text
  end
  
  defp format_markdown(text, entities) do
    apply_entities(text, entities, fn content, type, data ->
      case type do
        "bold" -> "**#{content}**"
        "italic" -> "_#{content}_"
        "code" -> "`#{content}`"
        "pre" -> "```\n#{content}\n```"
        "text_link" -> "[#{content}](#{data[:url]})"
        _ -> content
      end
    end)
  end
  
  defp format_html(text, []) do
    text
  end

  defp format_html(text, entities) do
    apply_entities(text, entities, fn content, type, data ->
      case type do
        "bold" -> "<b>#{content}</b>"
        "italic" -> "<i>#{content}</i>"
        "code" -> "<code>#{content}</code>"
        "pre" -> "<pre>#{content}</pre>"
        "text_link" -> "<a href=\"#{data[:url]}\">#{content}</a>"
        _ -> content
      end
    end)
  end
  
  defp apply_entities(text, entities, formatter_fn) do
    utf16_list = :unicode.characters_to_list(text, :utf16)
    
    # Sort entities by offset descending so we process from end to start, avoiding offset shifts
    sorted_entities = Enum.sort_by(entities, &(&1[:offset] || &1["offset"] || 0), :desc)
    
    result_utf16 = Enum.reduce(sorted_entities, utf16_list, fn entity, acc ->
      offset = entity[:offset] || entity["offset"] || 0
      length = entity[:length] || entity["length"] || 0
      type = entity[:type] || entity["type"]
      url = entity[:url] || entity["url"]
      
      {before_part, rest} = Enum.split(acc, offset)
      {content_part, after_part} = Enum.split(rest, length)
      
      content_str = :unicode.characters_to_binary(content_part, :utf16, :utf8)
      formatted_content = formatter_fn.(content_str, type, %{url: url})
      formatted_utf16 = :unicode.characters_to_list(formatted_content, :utf16)
      
      before_part ++ formatted_utf16 ++ after_part
    end)
    
    :unicode.characters_to_binary(result_utf16, :utf16, :utf8)
  end
end
