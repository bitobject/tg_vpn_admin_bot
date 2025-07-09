# Схема администратора (перенос из core)
defmodule AdminApiWeb.Admin do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}
  schema "admins" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :role, Ecto.Enum, values: [:admin, :superadmin]
    field :active, :boolean, default: true
    field :last_login_at, :utc_datetime
    timestamps()
  end

  @doc false
  def changeset(admin, attrs) do
    admin
    |> cast(attrs, [:email, :username, :password_hash, :role, :active, :last_login_at])
    |> validate_required([:email, :username, :role])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  def update_changeset(admin, attrs) do
    admin
    |> cast(attrs, [:email, :username, :role, :active, :last_login_at])
    |> validate_required([:email, :username, :role])
  end

  def update_last_login(admin) do
    change(admin, last_login_at: DateTime.utc_now())
  end
end
