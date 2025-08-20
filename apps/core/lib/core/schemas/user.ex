defmodule Core.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:username, :string, []}
  @foreign_key_type :string
  schema "telegram_users" do
    # The primary key is the user's telegram @username

    # The user's unique telegram ID
    field(:telegram_id, :integer, source: :id)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:language_code, :string)
    field(:is_bot, :boolean, default: false)

    # List of usernames created for this user in Marzban
    field(:marzban_users, {:array, :string}, default: [])

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :username,
      :telegram_id,
      :first_name,
      :last_name,
      :language_code,
      :marzban_users,
      :is_bot
    ])
    |> validate_required([:username, :telegram_id, :first_name])
    |> unique_constraint(:telegram_id, name: :telegram_users_id_index)
  end
end
