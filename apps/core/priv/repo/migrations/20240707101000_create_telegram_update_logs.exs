defmodule Core.Repo.Migrations.CreateTelegramUpdateLogs do
  use Ecto.Migration

  def change do
    create table(:telegram_update_logs) do
      add :user_id, :bigint
      add :update, :map, null: false
      timestamps()
    end
    create index(:telegram_update_logs, [:user_id])
    create index(:telegram_update_logs, [:inserted_at])
  end
end
