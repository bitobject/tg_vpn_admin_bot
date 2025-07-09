defmodule Core.Repo.Migrations.CreateAdmins do
  use Ecto.Migration

  def change do
    create table(:admins, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :email, :string, null: false
      add :username, :string, null: false
      add :password_hash, :string, null: false
      add :role, :string, null: false, default: "admin"
      add :is_active, :boolean, null: false, default: true
      add :last_login_at, :utc_datetime

      timestamps()
    end

    create unique_index(:admins, [:email])
    create unique_index(:admins, [:username])
    create index(:admins, [:role])
    create index(:admins, [:is_active])
  end
end
