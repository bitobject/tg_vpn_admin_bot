defmodule Core.Accounts.Admin do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "admins" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :role, Ecto.Enum, values: [:admin], default: :admin
    field :is_active, :boolean, default: true
    field :last_login_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password, :password_confirmation, :role, :is_active])
    |> validate_required([:email, :username, :password, :password_confirmation])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_length(:username, min: 3, max: 50)
    |> validate_length(:password, min: 8, max: 80)
    |> validate_confirmation(:password, message: "does not match password")
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> put_password_hash()
  end

  @doc false
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :role, :is_active])
    |> validate_required([:email, :username])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_length(:username, min: 3, max: 50)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @doc false
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8, max: 80)
    |> validate_confirmation(:password, message: "does not match password")
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, %{password_hash: Bcrypt.hash_pwd_salt(password)})
  end

  defp put_password_hash(changeset), do: changeset

  @doc """
  Returns a list of active users.
  """
  def list_active_admins do
    from(a in __MODULE__, where: a.is_active == true)
  end

  @doc """
  Gets a single admin by email.
  """
  def get_admin_by_email(email) when is_binary(email) do
    from(a in __MODULE__, where: a.email == ^email and a.is_active == true)
  end

  @doc """
  Gets a single admin by username.
  """
  def get_admin_by_username(username) when is_binary(username) do
    from(a in __MODULE__, where: a.username == ^username and a.is_active == true)
  end

  @doc """
  Updates the last login timestamp for an admin.
  """
  def update_last_login(admin) do
    admin
    |> change(%{last_login_at: DateTime.utc_now()})
  end
end
