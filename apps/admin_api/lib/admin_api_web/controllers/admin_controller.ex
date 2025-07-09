defmodule AdminApiWeb.AdminController do
  use AdminApiWeb, :controller

  alias AdminApiWeb.AdminContext
  alias AdminApiWeb.Admin

    @doc """
  Lists all admins.
  """
  def index(conn, _params) do
    admins = AdminContext.list_admins()

    conn
    |> put_status(:ok)
    |> json(%{
      admins: Enum.map(admins, &serialize_admin/1)
    })
  end

  @doc """
  Gets a single admin.
  """
  def show(conn, %{"id" => id}) do
    try do
      admin = AdminContext.get_admin!(id)

      conn
      |> put_status(:ok)
      |> json(%{admin: serialize_admin(admin)})
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Admin not found"})
    end
  end

  @doc """
  Creates a new admin.
  """
  def create(conn, %{"admin" => admin_params}) do
    case AdminContext.create_admin(admin_params) do
      {:ok, admin} ->
        conn
        |> put_status(:created)
        |> json(%{admin: serialize_admin(admin)})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Admin parameters are required"})
  end

  @doc """
  Updates an admin.
  """
  def update(conn, %{"id" => id, "admin" => admin_params}) do
    try do
      admin = AdminContext.get_admin!(id)

      case AdminContext.update_admin(admin, admin_params) do
        {:ok, updated_admin} ->
          conn
          |> put_status(:ok)
          |> json(%{admin: serialize_admin(updated_admin)})

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Admin not found"})
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Admin ID and parameters are required"})
  end

  @doc """
  Deletes an admin.
  """
  def delete(conn, %{"id" => id}) do
    try do
      admin = AdminContext.get_admin!(id)

      case AdminContext.delete_admin(admin) do
        {:ok, _admin} ->
          conn
          |> put_status(:ok)
          |> json(%{message: "Admin deleted successfully"})

        {:error, _changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "Failed to delete admin"})
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Admin not found"})
    end
  end

  def delete(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Admin ID is required"})
  end

  defp serialize_admin(%Admin{} = admin) do
    %{
      id: admin.id,
      email: admin.email,
      username: admin.username,
      role: admin.role,
      is_active: admin.active,
      last_login_at: admin.last_login_at,
      inserted_at: admin.inserted_at,
      updated_at: admin.updated_at
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
