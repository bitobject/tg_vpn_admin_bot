# Перенос миграции создания таблицы telegram_update_logs
defmodule TelegramApi.Repo.Migrations.CreateTelegramUpdateLogs do
  use Ecto.Migration

  def change do
    create table(:telegram_update_logs) do
      add :user_id, :bigint
      add :update, :map, null: false
      timestamps()
    end
    create index(:telegram_update_logs, [:user_id])
  end
end
