# Схема TelegramUser (перенос из core)
defmodule TelegramUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:username, :string, autogenerate: false}
  @foreign_key_type :string
  schema "telegram_users" do
    # Original Telegram user ID, kept for reference
    field(:id, :integer)
    field(:is_bot, :boolean)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:language_code, :string)
    field(:is_premium, :boolean)
    field(:added_to_attachment_menu, :boolean)
    field(:can_join_groups, :boolean)
    field(:can_read_all_group_messages, :boolean)
    field(:supports_inline_queries, :boolean)
    field(:can_connect_to_business, :boolean)

    field :marzban_users, {:array, :string}, default: []

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :id,
      :username,
      :is_bot,
      :first_name,
      :last_name,
      :language_code,
      :is_premium,
      :added_to_attachment_menu,
      :can_join_groups,
      :can_read_all_group_messages,
      :supports_inline_queries,
      :can_connect_to_business,
      :marzban_users
    ])
    |> validate_required([:id, :username, :is_bot, :first_name])
    |> unique_constraint(:id)
  end
end
