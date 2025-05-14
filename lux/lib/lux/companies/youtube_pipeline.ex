defmodule Lux.Companies.YouTubePipeline do
  @moduledoc """
  An automated content creation and optimization pipeline for YouTube channels.
  Coordinates script generation, visual optimization, metadata management, and A/B testing.
  """
  use Lux.Company

  company do
    name("YouTube Content Creation Pipeline")
    mission("Produce high-quality, fully optimized YouTube videos from raw concepts")

    has_ceo "Content Director" do
      agent(Lux.Agents.YouTube.ScriptGenerator)
      goal("Direct the overall video creation and ensure script quality")
      can("script_generation")
      can("hook_writing")
      can("content_structuring")
    end

    members do
      has_role "Visual Optimizer" do
        agent(Lux.Agents.YouTube.VisualOptimizer)
        goal("Optimize thumbnails and video pacing")
        can("thumbnail_ideation")
        can("broll_suggestion")
        can("pacing_analysis")
      end

      has_role "Metadata Manager" do
        agent(Lux.Agents.YouTube.MetadataManager)
        goal("Maximize SEO and search discovery")
        can("seo_optimization")
        can("tag_generation")
        can("description_writing")
      end

      has_role "Content Tester" do
        agent(Lux.Agents.YouTube.ContentTester)
        goal("A/B test variations to ensure high CTR")
        can("ab_testing")
        can("performance_analysis")
        can("variation_generation")
      end
    end
  end

  objective :create_optimized_video do
    description("Takes a raw topic and generates a complete, optimized YouTube content package")

    success_criteria(
      "Script, visual plan, metadata, and testing plan are all generated and mutually consistent"
    )

    steps([
      "Generate the script and hook based on the topic",
      "Propose visual optimization (thumbnails and b-roll) based on the script",
      "Generate SEO-optimized metadata",
      "Create an A/B testing plan for the generated assets"
    ])

    input(%{
      required: ["topic", "target_audience"],
      properties: %{
        "topic" => %{
          type: "string",
          description: "The main topic or idea for the YouTube video"
        },
        "target_audience" => %{
          type: "object",
          description: "Details about the target audience demographics and interests",
          properties: %{
            "age_range" => %{type: "string"},
            "interests" => %{type: "array", items: %{type: "string"}}
          }
        }
      }
    })
  end
end
