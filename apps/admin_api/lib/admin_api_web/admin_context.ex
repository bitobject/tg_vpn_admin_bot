# Контекст для работы с администраторами (CRUD, аутентификация)
defmodule AdminApiWeb.AdminContext do
  import Ecto.Query, warn: false
  alias AdminApiWeb.Admin
  alias AdminApi.Repo

  def list_admins, do: Repo.all(Admin)
  def list_active_admins, do: Repo.all(from a in Admin, where: a.active == true)
  def get_admin!(id), do: Repo.get!(Admin, id)
  def get_admin_by_email(email) when is_binary(email), do: Repo.get_by(Admin, email: email)
  def get_admin_by_username(username) when is_binary(username), do: Repo.get_by(Admin, username: username)

  def create_admin(attrs \\ %{}) do
    %Admin{}
    |> Admin.changeset(attrs)
    |> Repo.insert()
  end

  def update_admin(%Admin{} = admin, attrs) do
    admin
    |> Admin.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_admin(%Admin{} = admin), do: Repo.delete(admin)
  def change_admin(%Admin{} = admin, attrs \\ %{}), do: Admin.changeset(admin, attrs)

  def authenticate_admin(login, password) when is_binary(login) and is_binary(password) do
    admin = get_admin_by_email(login) || get_admin_by_username(login)
    case admin do
      nil -> {:error, :not_found}
      admin ->
        if Bcrypt.verify_pass(password, admin.password_hash) do
          {:ok, admin}
        else
          {:error, :invalid_password}
        end
    end
  end

  def ensure_admin_exists(attrs) do
    case Repo.one(from a in Admin, where: a.role == :admin, limit: 1) do
      nil -> create_admin(Map.put(attrs, :role, :admin))
      _admin -> {:error, :admin_already_exists}
    end
  end

  def update_admin_last_login(%Admin{} = admin) do
    admin
    |> Admin.update_last_login()
    |> Repo.update()
  end
end
