defmodule TelegramApi.HookHandler do
  use Telegex.GenAngler

  require Logger

  alias TelegramContext

  @impl true
  def on_boot do
    {:ok, user} = Telegex.Instance.fetch_me()
    Logger.info("Bot @#{user.username} starting in webhook mode...")

    webhook_url = Application.get_env(:telegex, :webhook_url)
    secret_token = Application.get_env(:telegex, :secret_token)
    server_port = Application.get_env(:telegex, :telegram_port_webhook)

    # Delete any old webhook and set the new one
    with {:ok, true} <- Telegex.delete_webhook(),
         {:ok, true} <- Telegex.set_webhook(webhook_url, secret_token: secret_token) do
      Logger.info("Successfully set webhook to #{webhook_url}")
    else
      error -> Logger.error("Failed to set webhook: #{inspect(error)}")
    end

    Logger.info("DEBUG: Using secret token for webhook: '#{secret_token}'")

    # This config struct is crucial. It tells Telegex to start its own web server.
    config = %Telegex.Hook.Config{
      server_port: server_port,
      secret_token: secret_token
    }

    Logger.info("Telegex webhook server starting on port #{server_port}")

    config
  end

  @impl true
  def on_update(update) do
    _user_id = get_user_id(update)
    # TelegramContext.log_update(%{user_id: user_id, update: update})

    # All updates are now processed through the chain handler.
    TelegramApi.ChainHandler.call(update, %TelegramApi.ChainContext{bot: Telegex.Instance.bot()})
  end

  defp get_user_id(%{"message" => %{"from" => %{"id" => id}}}), do: id
  defp get_user_id(%{"edited_message" => %{"from" => %{"id" => id}}}), do: id
  defp get_user_id(%{"callback_query" => %{"from" => %{"id" => id}}}), do: id
  defp get_user_id(_), do: nil
end
