defmodule Core.Context do
  @moduledoc """
  The boundary for the Core application.
  """

  alias Core.Repo

  alias Core.Schemas.User
  alias Core.Schemas.TelegramUpdateLog

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

  def get_user_by_username(username) do
    Repo.get(User, username)
  end

  def create_or_update_user(attrs) do
    case get_user_by_telegram_id(attrs.telegram_id) do
      nil ->
        %User{}
        |> User.changeset(attrs)
        |> Repo.insert()

      user ->
        user
        |> User.changeset(attrs)
        |> Repo.update()
    end
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

  #
  # Telegram Update Log
  #

  def log_update(attrs) do
    %TelegramUpdateLog{}
    |> Core.Schemas.TelegramUpdateLog.changeset(attrs)
    |> Repo.insert()
  end

end
