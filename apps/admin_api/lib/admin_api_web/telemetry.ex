defmodule AdminApiWeb.Telemetry do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will retrieve the following runtime measurements
      # on a schedule:
      #  * VM stats - `:vm.memory.total`, `:vm.total_run_queue_lengths.total`
      #  * Database stats - `:core.repo.query.total_time`...
      #  * Phoenix stats - `:phoenix.endpoint.start.duration`...
      #
      # You may also extend this list with your own custom metrics.
      # {TelemetryPoller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {TelemetryMetricsPrometheus, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # {AdminApi, :count_users, []}
    ]
  end
end
