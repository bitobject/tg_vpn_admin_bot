defmodule Core.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo
  alias Core.Accounts.Admin

    @doc """
  Returns the list of admins.
  """
  def list_admins do
    Repo.all(Admin)
  end

  @doc """
  Returns the list of active admins.
  """
  def list_active_admins do
    Repo.all(Admin.list_active_admins())
  end

  @doc """
  Gets a single admin.
  """
  def get_admin!(id), do: Repo.get!(Admin, id)

  @doc """
  Gets a single admin by email.
  """
  def get_admin_by_email(email) when is_binary(email) do
    Repo.one(Admin.get_admin_by_email(email))
  end

  @doc """
  Gets a single admin by username.
  """
  def get_admin_by_username(username) when is_binary(username) do
    Repo.one(Admin.get_admin_by_username(username))
  end

  @doc """
  Creates an admin.
  """
  def create_admin(attrs \\ %{}) do
    %Admin{}
    |> Admin.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an admin.
  """
  def update_admin(%Admin{} = admin, attrs) do
    admin
    |> Admin.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates an admin's password.
  """
  def update_admin_password(%Admin{} = admin, attrs) do
    admin
    |> Admin.password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the last login timestamp for an admin.
  """
  def update_admin_last_login(%Admin{} = admin) do
    admin
    |> Admin.update_last_login()
    |> Repo.update()
  end

  @doc """
  Deletes an admin.
  """
  def delete_admin(%Admin{} = admin) do
    Repo.delete(admin)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking admin changes.
  """
  def change_admin(%Admin{} = admin, attrs \\ %{}) do
    Admin.changeset(admin, attrs)
  end

  @doc """
  Authenticates an admin by username/email and password.
  """
  def authenticate_admin(login, password) when is_binary(login) and is_binary(password) do
    admin = get_admin_by_email(login) || get_admin_by_username(login)

    case admin do
      nil ->
        {:error, :not_found}
      admin ->
        if Bcrypt.verify_pass(password, admin.password_hash) do
          {:ok, admin}
        else
          {:error, :invalid_password}
        end
    end
  end

  @doc """
  Creates an admin if no admin exists.
  """
  def ensure_admin_exists(attrs) do
    case Repo.one(from a in Admin, where: a.role == :admin, limit: 1) do
      nil ->
        create_admin(Map.put(attrs, :role, :admin))
      _admin ->
        {:error, :admin_already_exists}
    end
  end
end
