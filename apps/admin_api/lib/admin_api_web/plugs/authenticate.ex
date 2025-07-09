defmodule AdminApiWeb.Plugs.Authenticate do
  @moduledoc """
  Plug for authenticating users via JWT tokens.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias AdminApi.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_token(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})
        |> halt()
      token ->
        case Guardian.resource_from_token(token) do
          {:ok, admin, _claims} ->
            assign(conn, :current_admin, admin)
          {:error, _reason} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid token"})
            |> halt()
        end
    end
  end

  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end
end
