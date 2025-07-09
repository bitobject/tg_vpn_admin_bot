# Перенос миграции создания таблицы админов
defmodule AdminApi.Repo.Migrations.CreateAdmins do
  use Ecto.Migration

  def change do
    create table(:admins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :username, :string, null: false
      add :password_hash, :string, null: false
      add :role, :string, null: false
      add :active, :boolean, default: true, null: false
      add :last_login_at, :utc_datetime
      timestamps()
    end
    create unique_index(:admins, [:email])
    create unique_index(:admins, [:username])
  end
end
