defmodule Core.Queries.UserQueries do
  @moduledoc """
  Context for querying users.
  """
  import Ecto.Query, warn: false

  alias Core.Repo
  alias Core.Schemas.User

  @doc """
  Gets a user by telegram_id.

  ## Examples

      iex> get_by_telegram_id(123)
      %User{} | nil

  """
  def get_by_telegram_id(telegram_id) do
    Repo.get_by(User, telegram_id: telegram_id)
  end
end
