defmodule AdminApiWeb.Plugs.Authorize do
  @moduledoc """
  Plug for authorizing users based on their role.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(required_role) when is_atom(required_role) do
    required_role
  end

  def call(conn, required_role) do
    admin = conn.assigns[:current_admin]

    case admin do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})
        |> halt()
      admin ->
        if has_role?(admin, required_role) do
          conn
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Insufficient permissions"})
          |> halt()
        end
    end
  end

  defp has_role?(admin, :admin) do
    admin.role == :admin
  end

  defp has_role?(_admin, _role) do
    false
  end
end
