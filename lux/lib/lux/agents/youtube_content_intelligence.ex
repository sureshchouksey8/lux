defmodule Lux.Agents.YouTubeContentIntelligence do
  @moduledoc """
  An agent that analyzes YouTube content, engagement, and metadata using AI models
  and provides predictive analytics for optimal posting times and performance.

  ## Examples

      iex> {:ok, agent} = Lux.Agents.YouTubeContentIntelligence.start_link([])
      iex> video_context = %{
      ...>   "title" => "My new vlog",
      ...>   "metrics" => %{"views" => 100, "likes" => 10}
      ...> }
      iex> Lux.Agents.YouTubeContentIntelligence.optimize_content(agent, video_context)
      {:ok, %{title: "Optimized Title", ...}}

      iex> metrics = [%{"hour" => 10, "views" => 1000}, %{"hour" => 18, "views" => 5000}]
      iex> Lux.Agents.YouTubeContentIntelligence.predict_performance(metrics)
      %{"optimal_posting_hour" => 18, "predicted_views" => 5750, "confidence_score" => 0.2}
  """

  use Lux.Agent,
    name: "YouTube Content Intelligence",
    description: "Analyzes YouTube metrics and generates metadata for content optimization",
    goal: "Provide actionable insights, predictions, and metadata to optimize YouTube channel growth",
    capabilities: [
      :content_analysis,
      :metadata_generation,
      :performance_prediction,
      :optimal_posting_time
    ],
    llm_config: %{
      model: "gpt-4o-mini",
      temperature: 0.7,
      json_response: true,
      json_schema: %{
        name: "content_optimization",
        schema: %{
          type: "object",
          properties: %{
            title: %{
              type: "string",
              description: "Optimized video title"
            },
            description: %{
              type: "string",
              description: "Generated SEO description"
            },
            tags: %{
              type: "array",
              items: %{type: "string"},
              description: "Optimized tags"
            },
            thumbnails_ideas: %{
              type: "array",
              items: %{type: "string"},
              description: "Thumbnail concepts"
            },
            engagement_analysis: %{
              type: "string",
              description: "Audience engagement summary"
            },
            trending_topics: %{
              type: "array",
              items: %{type: "string"},
              description: "Related trending topics"
            },
            content_recommendations: %{
              type: "array",
              items: %{type: "string"},
              description: "Ideas for future videos based on analysis"
            }
          },
          required: [
            "title",
            "description",
            "tags",
            "thumbnails_ideas",
            "engagement_analysis",
            "trending_topics",
            "content_recommendations"
          ]
        }
      },
      messages: [
        %{
          role: "system",
          content: """
          You are a YouTube Content Intelligence Agent. Given video details, channel metrics,
          and content topics, you provide optimized metadata and actionable insights.
          Your recommendations must be in valid JSON format.
          """
        }
      ]
    }

  require Logger
  require Lux.Python

  @doc """
  Generates metadata and content recommendations based on video context and historical performance.
  """
  def optimize_content(agent, video_context) do
    with {:ok, analysis} <-
           send_message(agent, """
           Analyze the following video context and provide optimizations:
           #{Jason.encode!(video_context, pretty: true)}

           Respond with the complete optimization JSON including ALL required fields.
           """) do
      {:ok, Jason.decode!(analysis, keys: :atoms)}
    end
  end

  @doc """
  Uses Python machine learning models (simulated logic) via Lux.Python to predict the best
  posting time and view performance for a given channel's historical metrics.
  """
  def predict_performance(metrics) do
    Lux.Python.python variables: %{metrics: metrics} do
      ~PY'''
      import json

      if not metrics:
          result = {
              "optimal_posting_hour": 17,
              "predicted_views": 5000,
              "confidence_score": 0.5
          }
      else:
          hour_views = {}
          total_views = 0
          for m in metrics:
              h = m.get("hour", 0)
              v = m.get("views", 0)
              hour_views.setdefault(h, []).append(v)
              total_views += v
          
          best_hour = 17
          max_avg = -1
          for h, vs in hour_views.items():
              avg = sum(vs) / len(vs)
              if avg > max_avg:
                  max_avg = avg
                  best_hour = h
          
          # Machine learning simulation for performance prediction
          predicted_views = int(max_avg * 1.15) if max_avg > 0 else 5000
          confidence_score = min(0.95, len(metrics) * 0.1)

          result = {
              "optimal_posting_hour": best_hour,
              "predicted_views": predicted_views,
              "confidence_score": confidence_score
          }

      result
      '''
    end
  end
end
