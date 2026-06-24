defmodule Lux.Integration.Agents.YouTubeContentIntelligenceTest do
  use ExUnit.Case, async: true

  alias Lux.Agents.YouTubeContentIntelligence

  @moduletag :integration

  setup do
    # Using start_link to initialize the agent with basic config
    {:ok, agent} = YouTubeContentIntelligence.start_link([])
    %{agent: agent}
  end

  test "predict_performance returns optimal posting hour and predicted views based on mock metrics" do
    historical_metrics = [
      %{"hour" => 10, "views" => 1000},
      %{"hour" => 10, "views" => 1500},
      %{"hour" => 18, "views" => 5000},
      %{"hour" => 18, "views" => 6000},
      %{"hour" => 20, "views" => 3000}
    ]

    result = YouTubeContentIntelligence.predict_performance(historical_metrics)

    # The max average is at hour 18: (5000 + 6000) / 2 = 5500
    # Predicted views should be 5500 * 1.15 = 6325
    assert result["optimal_posting_hour"] == 18
    assert result["predicted_views"] == trunc(5500 * 1.15)
    # Confidence score: min(0.95, len(metrics) * 0.1) -> min(0.95, 5 * 0.1) = 0.5
    assert result["confidence_score"] == 0.5
  end

  test "predict_performance handles empty metrics gracefully" do
    result = YouTubeContentIntelligence.predict_performance([])
    assert result["optimal_posting_hour"] == 17
    assert result["predicted_views"] == 5000
    assert result["confidence_score"] == 0.5
  end
end
