defmodule Lux.YouTube.Agents.AnalyticsAgent do
  @moduledoc false
  use Lux.Agent,
    template: :company_agent,
    name: "AnalyticsAgent",
    description: "Analyzes video performance and audience engagement",
    capabilities: ["analyze_video_performance", "analyze_audience_engagement"],
    signal_handlers: [
      {Lux.Schemas.Companies.TaskSignal,
       {Lux.Agent.Companies.SignalHandler.DefaultImplementation, :handle_task_assignment}}
    ],
    template_opts: %{
      llm_config: %{
        provider: :open_ai,
        model: "gpt-4o",
        temperature: 0.7,
        max_tokens: 500,
        api_key: ""
      }
    }
end

defmodule Lux.YouTube.Agents.OptimizationAgent do
  @moduledoc false
  use Lux.Agent,
    template: :company_agent,
    name: "OptimizationAgent",
    description: "Optimizes content metadata and posting times",
    capabilities: [
      "optimize_title_thumbnail",
      "optimize_tags",
      "generate_description",
      "predict_posting_time"
    ],
    signal_handlers: [
      {Lux.Schemas.Companies.TaskSignal,
       {Lux.Agent.Companies.SignalHandler.DefaultImplementation, :handle_task_assignment}}
    ],
    template_opts: %{
      llm_config: %{
        provider: :open_ai,
        model: "gpt-4o",
        temperature: 0.7,
        max_tokens: 1000,
        api_key: ""
      }
    }
end

defmodule Lux.YouTube.Agents.StrategyAgent do
  @moduledoc false
  use Lux.Agent,
    template: :company_agent,
    name: "StrategyAgent",
    description: "Recommends content ideas based on trending topics",
    capabilities: ["recommend_content", "analyze_trending_topics"],
    signal_handlers: [
      {Lux.Schemas.Companies.TaskSignal,
       {Lux.Agent.Companies.SignalHandler.DefaultImplementation, :handle_task_assignment}}
    ],
    template_opts: %{
      llm_config: %{
        provider: :open_ai,
        model: "gpt-4o",
        temperature: 0.9,
        max_tokens: 1500,
        api_key: ""
      }
    }
end
