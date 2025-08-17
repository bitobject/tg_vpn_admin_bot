defmodule Core.Repo.Migrations.AddMarzbanUsersToTelegramUsers do
  use Ecto.Migration

  def change do
    alter table(:telegram_users) do
      add :marzban_users, {:array, :string}, default: [], null: false
    end
  end
end
