defmodule TelegramApi.HookHandler do
  use Telegex.Hook.GenHandler

  require Logger

  alias TelegramContext

  @impl true
  def on_boot do
    {:ok, user} = Telegex.Instance.cache_me()
    Logger.info("Booting Telegram Bot Handler...")

    webhook_url = System.get_env("WEBHOOK_URL")
    secret_token = System.get_env("TELEGRAM_BOT_TOKEN")

    with {:ok, true} <- Telegex.delete_webhook(),
         {:ok, true} <- Telegex.set_webhook(webhook_url, secret_token: secret_token) do
      Logger.info("Successfully set webhook to #{webhook_url} with token #{secret_token}")
    else
      error -> Logger.error("Failed to set webhook: #{inspect(error)}")
    end

    Logger.info("Bot (@#{user.username}) is working (webhook)")

    # Return the config. We can use the port from our app config.
    server_port = Application.get_env(:telegex, :telegram_port_webhook)
    %Telegex.Hook.Config{server_port: server_port, secret_token: secret_token}
  end

  @impl true
  def on_update(update) do
    IO.inspect(inspect(update), label: "Update")
    # Log every update
    user_id = get_user_id(update)
    TelegramContext.log_update(%{user_id: user_id, update: update})

    # Manually handle commands and other messages
    # Manually handle commands and other messages
    case update do
      %{"message" => %{"text" => "/start" <> _, "from" => from, "chat" => chat}} ->
        handle_start(from, chat)

      _ ->
        # Ignore other messages for now
        Logger.info("Received unknown update: #{inspect(update)}")
        :ok
    end
  end

  defp handle_start(from_map, chat_map) do
    # The `from` and `chat` are plain maps here, not structs
    attrs = telegram_user_attrs(from_map)
    TelegramContext.create_or_update_user(attrs)

    greeting = greeting_text(from_map)
    Telegex.send_message(chat_map["id"], greeting)
  end

  defp telegram_user_attrs(from) do
    %{
      id: from["id"],
      first_name: from["first_name"],
      last_name: from["last_name"],
      username: from["username"],
      language_code: from["language_code"]
    }
  end

  defp greeting_text(from) do
    """
    Hi, #{from["first_name"]}!
    Welcome to our bot.
    """
  end

  defp get_user_id(%{"message" => %{"from" => %{"id" => id}}}), do: id
  defp get_user_id(%{"edited_message" => %{"from" => %{"id" => id}}}), do: id
  defp get_user_id(%{"callback_query" => %{"from" => %{"id" => id}}}), do: id
  defp get_user_id(_), do: nil
end
