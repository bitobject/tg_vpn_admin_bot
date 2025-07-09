# Перенос миграции создания таблицы telegram_users
defmodule TelegramApi.Repo.Migrations.CreateTelegramUsers do
  use Ecto.Migration

  def change do
    create table(:telegram_users, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :is_bot, :boolean, null: false
      add :first_name, :string, null: false
      add :last_name, :string
      add :username, :string
      add :language_code, :string
      add :is_premium, :boolean
      add :added_to_attachment_menu, :boolean
      add :can_join_groups, :boolean
      add :can_read_all_group_messages, :boolean
      add :supports_inline_queries, :boolean
      timestamps()
    end
    create unique_index(:telegram_users, [:username])
  end
end
