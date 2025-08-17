defmodule Core.Repo.Migrations.CreateTariffs do
  use Ecto.Migration

  def change do
    create table(:tariffs) do
      add :name, :string, null: false
      add :description, :text
      add :price, :integer, null: false
      add :currency, :string, null: false, size: 3
      add :duration_days, :integer, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create index(:tariffs, [:name])
    create unique_index(:tariffs, [:name, :is_active])
  end
end
