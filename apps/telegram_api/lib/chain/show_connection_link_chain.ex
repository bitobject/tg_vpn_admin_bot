defmodule TelegramApi.Chain.ShowConnectionLinkChain do
  use Telegex.Chain

  require Logger

  alias TelegramApi.Marzban
  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{id: query_id, data: "show_connection_link:" <> username}
        } = update,
        context
      ) do
    with {:ok, chat_id} <- Telegram.get_chat_id(update) do
      Task.start(fn ->
        case Marzban.get_user(username) do
          {:ok, marzban_user} ->
            send_connection_details(chat_id, query_id, marzban_user)

          {:error, reason} ->
            Logger.error("Failed to get user from Marzban in ShowConnectionLinkChain: #{inspect(reason)}")
            Telegram.send_message(chat_id, "Не удалось получить информацию о подключении.")
        end
      end)
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  defp send_connection_details(chat_id, query_id, marzban_user) do
    base_url = marzban_base_url()
    relative_url = marzban_user["subscription_url"]
    full_subscription_url = base_url <> relative_url

    qr_code_url =
      "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=#{URI.encode(full_subscription_url)}"

    caption = """
    *Подключение*: `#{marzban_user["username"]}`

    Ваша ссылка на подключение отображается во всплывающем окне.
    """

    Telegram.send_photo(chat_id, qr_code_url,
      caption: caption,
      parse_mode: "Markdown"
    )

    Telegram.answer_callback_query(query_id, text: full_subscription_url, show_alert: true)
  end

  defp marzban_base_url do
    Application.get_env(:telegram_api, :marzban)[:base_url]
  end
end
