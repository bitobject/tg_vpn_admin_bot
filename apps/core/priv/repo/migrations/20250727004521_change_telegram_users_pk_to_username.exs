defmodule Core.Repo.Migrations.ChangeTelegramUsersPkToUsername do
  use Ecto.Migration

  def up do
    # Drop the old table to redefine the primary key and structure cleanly.
    drop table(:telegram_users)

    create table(:telegram_users, primary_key: false) do
      # username is the new primary key
      add :username, :string, primary_key: true

      # The original Telegram ID, kept for reference and uniqueness.
      add :id, :bigint, null: false

      add :is_bot, :boolean, null: false
      add :first_name, :string, null: false
      add :last_name, :string
      add :language_code, :string
      add :is_premium, :boolean
      add :added_to_attachment_menu, :boolean
      add :can_join_groups, :boolean
      add :can_read_all_group_messages, :boolean
      add :supports_inline_queries, :boolean
      add :can_connect_to_business, :boolean # New field

      timestamps()
    end

    # Ensure the original Telegram ID remains unique.
    create unique_index(:telegram_users, [:id])
  end

  def down do
    # Revert to the old structure if needed.
    drop table(:telegram_users)

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

    create unique_index(:telegram_users, [:id])
    create index(:telegram_users, [:username])
  end
end
