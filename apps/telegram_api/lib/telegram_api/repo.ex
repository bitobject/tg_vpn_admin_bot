defmodule TelegramApi.Repo do
  use Ecto.Repo,
    otp_app: :telegram_api,
    adapter: Ecto.Adapters.Postgres
end
