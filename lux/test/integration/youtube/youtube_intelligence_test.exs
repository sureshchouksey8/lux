defmodule Lux.Integration.YouTube.YouTubeIntelligenceTest do
  @moduledoc """
  Integration tests showcasing content optimization workflow for YouTube Intelligence System.
  """
  use IntegrationCase, async: true

  alias Lux.Company.Hub.Local
  alias Lux.YouTube.YouTubeIntelligence
  alias Lux.YouTube.Prisms.ContentRecommendationPrism

  @moduletag :integration

  describe "youtube content intelligence workflow" do
    setup do
      # Start a local hub for the company
      hub_name = :"hub_#{:erlang.unique_integer([:positive])}"
      table_name = :"table_#{:erlang.unique_integer([:positive])}"
      start_supervised!({Local, name: hub_name, table_name: table_name})

      # Get the company configuration
      company_config = YouTubeIntelligence.view()

      # Start the company
      {:ok, company_pid} =
        Lux.Company.start_link(YouTubeIntelligence, %{
          name: company_config.name,
          hub: hub_name
        })

      # Register the company with the hub
      {:ok, company_id} = Local.register_company(company_config, hub_name)

      %{company_pid: company_pid, hub: hub_name, company_id: company_id}
    end

    test "youtube agents expose the expected prisms" do
      assert Lux.YouTube.Prisms.PerformanceAnalyticsPrism in
               Lux.YouTube.Agents.AnalyticsAgent.view().prisms

      assert Lux.YouTube.Prisms.MetadataOptimizationPrism in
               Lux.YouTube.Agents.OptimizationAgent.view().prisms

      assert Lux.YouTube.Prisms.ContentRecommendationPrism in
               Lux.YouTube.Agents.StrategyAgent.view().prisms
    end

    test "successfully executes content optimization workflow", %{company_pid: pid, hub: hub, company_id: company_id} do
      # 1. Start objective
      {:ok, objective} =
        Lux.Company.run_objective(pid, :optimize_content_workflow, %{
          "topic" => "Elixir for AI Agents",
          "niche" => "Software Engineering",
          "video_data" => [
            %{
              "video_id" => "v1",
              "views" => 15000,
              "watch_time_hours" => 1200,
              "ctr" => 5.2,
              "avg_view_duration" => 6.5
            }
          ]
        })

      objective_id = objective.payload["id"]

      # 2. Wait for initial objective setup
      {:ok, initial_status} = Lux.Company.get_objective_status(pid, objective_id)
      assert initial_status == :in_progress

      # 3. Verify company structure
      {:ok, company} = Local.get_company(company_id, hub)
      assert company.name == "YouTube Content Intelligence System"
      assert length(company.roles) == 2
      assert company.ceo != nil

      # 4. Wait for completion with polling
      assert_receive_objective_completion(pid, objective_id, 50, 100)

      {:ok, final_status} = Lux.Company.get_objective_status(pid, objective_id)
      assert final_status == :completed

      # 5. Check the output artifacts strictly
      {:ok, artifacts} = Lux.Company.get_objective_artifacts(pid, objective_id)
      assert is_list(artifacts)
      assert length(artifacts) > 0

      Enum.each(artifacts, fn artifact ->
        assert Map.has_key?(artifact, :type)
        assert Map.has_key?(artifact, :content)
      end)
    end
  end

  defp assert_receive_objective_completion(_pid, _objective_id, 0, _delay), do: flunk("Objective timed out")
  defp assert_receive_objective_completion(pid, objective_id, retries, delay) do
    {:ok, status} = Lux.Company.get_objective_status(pid, objective_id)
    if status == :completed do
      :ok
    else
      :timer.sleep(delay)
      assert_receive_objective_completion(pid, objective_id, retries - 1, delay)
    end
  end
end
