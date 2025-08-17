defmodule Core.Schemas.Tariff do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tariffs" do
    field(:name, :string)
    field(:description, :string)
    field(:price, :integer)
    field(:currency, :string)
    field(:duration_days, :integer)
    field(:is_active, :boolean, default: true)

    timestamps()
  end

  @doc false
  def changeset(tariff, attrs) do
    tariff
    |> cast(attrs, [:name, :description, :price, :currency, :duration_days, :is_active])
    |> validate_required([:name, :price, :currency, :duration_days, :is_active])
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_number(:duration_days, greater_than: 0)
    |> unique_constraint(:name, name: :tariffs_name_is_active_index)
  end
end
