defmodule Core.Context do
  @moduledoc """
  The boundary for the Core application.
  """

  alias Core.Repo

  alias Core.Schemas.User
  alias Core.Queries.TariffQueries
  alias Core.Queries.UserQueries

  require Logger

  #
  # Tariffs
  #

  defdelegate list_active_tariffs, to: TariffQueries
  defdelegate get_tariff(id), to: TariffQueries
  defdelegate create_tariff(attrs), to: TariffQueries

  #
  # Users
  #

  defdelegate get_user_by_telegram_id(telegram_id), to: UserQueries, as: :get_by_telegram_id

  @doc """
  Gets a user by their Telegram ID, or creates a new one if not found.
  Returns the user struct on success, or nil on failure.
  """
  def get_or_create_user(%{telegram_id: telegram_id} = attrs) do
    case UserQueries.get_by_telegram_id(telegram_id) do
      nil ->
        Logger.info("User with telegram_id=#{telegram_id} not found, creating new one.")
        create_user(attrs)

      user ->
        # User already exists, return it.
        {:ok, user}
    end
    |> case do
      {:ok, user} ->
        user

      {:error, changeset} ->
        Logger.error("Failed to create or get user: #{inspect(changeset.errors)}")
        nil
    end
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Adds a new Marzban username to the user's list of connections.
  """
  def add_marzban_user_to_telegram_user(%User{} = user, marzban_username) do
    new_marzban_users = [marzban_username | user.marzban_users]

    user
    |> User.changeset(%{marzban_users: new_marzban_users})
    |> Repo.update()
  end
end
