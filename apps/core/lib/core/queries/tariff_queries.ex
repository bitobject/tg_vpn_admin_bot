defmodule Core.Queries.TariffQueries do
  @moduledoc """
  Context for querying tariffs.
  """
  import Ecto.Query, warn: false

  alias Core.Repo
  alias Core.Schemas.Tariff

  @doc """
  Returns the list of active tariffs, ordered by price.
  """
  def list_active_tariffs do
    from(t in Tariff, where: t.is_active == true, order_by: [asc: t.price])
    |> Repo.all()
  end

  def get_tariff(id) do
    Repo.get(Tariff, id)
  end

  @doc """
  Gets a single tariff by ID, raising an error if not found.
  """
  def get_tariff!(id) do
    Repo.get!(Tariff, id)
  end

  @doc """
  Creates a tariff.
  """
  def create_tariff(attrs) do
    %Tariff{}
    |> Tariff.changeset(attrs)
    |> Repo.insert()
  end
end
