defmodule Lux.YouTube.Prisms.MetadataOptimizationPrism do
  @moduledoc """
  Generates and optimizes metadata such as titles, tags, and descriptions for YouTube videos.
  """
  use Lux.Prism,
    name: "MetadataOptimizationPrism",
    description: "Optimizes title, tags, description and suggests posting times",
    input_schema: %{
      type: "object",
      properties: %{
        "topic" => %{
          type: "string",
          description: "The main topic or keyword of the video"
        },
        "target_audience" => %{
          type: "string",
          description: "The intended demographic or audience"
        }
      },
      required: ["topic"]
    },
    capabilities: [
      "optimize_title_thumbnail",
      "optimize_tags",
      "generate_description",
      "predict_posting_time"
    ]

  def handler(%{"topic" => topic} = input, _context) do
    audience = Map.get(input, "target_audience", "general audience")

    # This represents a mock of a machine learning model optimizing metadata
    titles = [
      "#{String.capitalize(topic)}: The Ultimate Guide for #{audience}",
      "I Tried #{topic} and This Happened...",
      "What You Need to Know About #{topic} in 2026"
    ]

    tags =
      topic
      |> String.downcase()
      |> String.split()
      |> Enum.map(&String.trim(&1, ","))
      |> Enum.concat(["viral", "trending", "tutorial", "guide", audience])
      |> Enum.uniq()
      |> Enum.take(15)

    description = """
    In this video, we dive deep into #{topic}.
    Perfect for #{audience} looking to understand the latest trends and techniques.

    Don't forget to like, subscribe, and hit the bell icon!

    # #{Enum.join(tags, " #")}
    """

    posting_times = [
      "Wednesday 3:00 PM EST",
      "Friday 12:00 PM EST",
      "Saturday 10:00 AM EST"
    ]

    {:ok,
     %{
       optimized_titles: titles,
       suggested_tags: tags,
       generated_description: description,
       optimal_posting_times: posting_times,
       thumbnail_ideas: [
         "High contrast text overlay with expressive face",
         "Before and after split screen",
         "Minimalist design with bold #{topic} graphic"
       ]
     }}
  end
end
