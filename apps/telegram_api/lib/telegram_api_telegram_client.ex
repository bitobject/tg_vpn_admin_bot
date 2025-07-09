defmodule TelegramApi.TelegramClient do
  @moduledoc """
  Клиент для отправки сообщений через Telegram Bot API.
  """
  @telegram_api "https://api.telegram.org/bot"

  def send_message(chat_id, text) do
    token = bot_token()
    url = "#{@telegram_api}#{token}/sendMessage"
    body = %{chat_id: chat_id, text: text}
    headers = [{"Content-Type", "application/json"}]
    HTTPoison.post(url, Jason.encode!(body), headers)
  end

  defp bot_token do
    Application.get_env(:telegram_api, :bot_token) ||
      raise "TELEGRAM_BOT_TOKEN not set"
  end
end
