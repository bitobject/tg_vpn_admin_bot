# Контекст для работы с TelegramUser и TelegramUpdateLog (перенос из core)
defmodule TelegramContext do
  import Ecto.Query, warn: false
  alias TelegramUser
  alias TelegramUpdateLog
  alias Core.Repo

  # TelegramUser
  def get_user(username), do: Repo.get(TelegramUser, username)

  def create_or_update_user(attrs) do
    # We use username as the primary key now.
    case get_user(attrs.username) do
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
  # Логирует апдейт Telegram с user_id (если есть).
  def log_update(%{user_id: user_id, update: update}) do
    %TelegramUpdateLog{user_id: user_id, update: update}
    |> TelegramUpdateLog.changeset(%{})
    |> Repo.insert()
  end

  # Логирует апдейт Telegram без user_id (например, если user_id не определён).
  def log_update(update) do
    %TelegramUpdateLog{update: update}
    |> TelegramUpdateLog.changeset(%{})
    |> Repo.insert()
  end
end
