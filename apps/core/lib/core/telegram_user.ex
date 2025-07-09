defmodule Core.TelegramUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false} # Telegram user_id
  schema "telegram_users" do
    field :is_bot, :boolean
    field :first_name, :string
    field :last_name, :string
    field :username, :string
    field :language_code, :string
    field :is_premium, :boolean
    field :added_to_attachment_menu, :boolean
    field :can_join_groups, :boolean
    field :can_read_all_group_messages, :boolean
    field :supports_inline_queries, :boolean
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :is_bot, :first_name, :last_name, :username, :language_code, :is_premium, :added_to_attachment_menu, :can_join_groups, :can_read_all_group_messages, :supports_inline_queries])
    |> validate_required([:id, :is_bot, :first_name])
  end
end
