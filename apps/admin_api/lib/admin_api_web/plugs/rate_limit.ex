defmodule AdminApiWeb.Plugs.RateLimit do
  @moduledoc """
  Plug for rate limiting API requests.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts) do
    Keyword.merge(
      [
        limit: 100,
        # 1 minute
        window: 60_000,
        key: :ip
      ],
      opts
    )
  end

  def call(conn, opts) do
    key = get_key(conn, opts[:key])
    limit = opts[:limit]
    window = opts[:window]

    case Hammer.check_rate(key, window, limit) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Rate limit exceeded"})
        |> halt()
    end
  end

  defp get_key(conn, :ip) do
    conn.remote_ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp get_key(conn, :admin_id) do
    case conn.assigns[:current_admin] do
      nil -> "anonymous"
      admin -> "admin:#{admin.id}"
    end
  end

  defp get_key(_conn, _key), do: "default"
end
