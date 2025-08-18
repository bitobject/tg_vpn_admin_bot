defmodule TelegramApi.Chain.ShowConnectionLinkChain do
  use Telegex.Chain

  require Logger

  alias TelegramApi.Marzban
  alias TelegramApi.Telegram
  alias TelegramApi.State

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{
            id: query_id,
            data: "show_connection_link:" <> username
          }
        } = update,
        context
      ) do
    Telegram.answer_callback_query(query_id)

    with {:ok, chat_id} <- Telegram.get_chat_id(update) do
      Task.start(fn ->
        case {Marzban.get_user(username), State.get_last_message_id(chat_id)} do
          {{:ok, marzban_user}, {:ok, message_id}} ->
            edit_message_with_connection_details(chat_id, message_id, marzban_user)

          {_, :not_found} ->
            Logger.error("Could not find last_message_id for chat_id #{chat_id} to edit.")

            Telegram.send_message(
              chat_id,
              "Произошла ошибка. Пожалуйста, вернитесь в главное меню и попробуйте снова."
            )

          {{:error, reason}, _} ->
            Logger.error(
              "Failed to get user from Marzban in ShowConnectionLinkChain: #{inspect(reason)}"
            )

            Telegram.send_message(chat_id, "Не удалось получить информацию о подключении.")
        end
      end)
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  defp edit_message_with_connection_details(chat_id, message_id, marzban_user) do
    base_url = marzban_base_url()
    relative_url = marzban_user["subscription_url"]
    full_subscription_url = base_url <> relative_url

    qr_code_url =
      "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=#{URI.encode(full_subscription_url)}"

    caption = """
    *Подключение*: `#{marzban_user["username"]}`

    *Ваша ссылка:*
    `#{full_subscription_url}`
    """

    media = %{
      "type" => "photo",
      "media" => qr_code_url,
      "caption" => caption,
      "parse_mode" => "Markdown"
    }

    Telegram.edit_message_media(chat_id, message_id, media)
  end

  defp marzban_base_url do
    Application.get_env(:telegram_api, :marzban)[:base_url]
  end
end
