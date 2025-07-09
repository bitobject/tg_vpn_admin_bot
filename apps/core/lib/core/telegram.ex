defmodule Core.Telegram do
  @moduledoc """
  Context для работы с Telegram-пользователями и логами апдейтов.
  """
  import Ecto.Query, warn: false
  alias Core.Repo
  alias Core.TelegramUser
  alias Core.TelegramUpdateLog

  # TelegramUser
  def get_user(id), do: Repo.get(TelegramUser, id)

  def get_user_by_username(username) when is_binary(username) do
    Repo.one(from u in TelegramUser, where: u.username == ^username)
  end

  def create_or_update_user(attrs) do
    case Repo.get(TelegramUser, attrs.id) do
      nil ->
        %TelegramUser{}
        |> TelegramUser.changeset(attrs)
        |> Repo.insert()
      user ->
        user
        |> TelegramUser.changeset(attrs)
        |> Repo.update()
    end
  end

  # TelegramUpdateLog
  def log_update(%{user_id: user_id, update: update}) do
    %TelegramUpdateLog{user_id: user_id, update: update}
    |> TelegramUpdateLog.changeset(%{})
    |> Repo.insert()
  end

  def log_update(update) do
    %TelegramUpdateLog{update: update}
    |> TelegramUpdateLog.changeset(%{})
    |> Repo.insert()
  end
end
