defmodule AdminApiWeb.HealthController do
  use AdminApiWeb, :controller

  @doc """
  Health check endpoint.
  """
  def check(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
      status: "healthy",
      timestamp: DateTime.utc_now(),
      version: "1.0.0"
    })
  end
end
