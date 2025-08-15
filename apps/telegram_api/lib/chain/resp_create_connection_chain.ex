defmodule TelegramApi.Chain.RespCreateConnectionChain do
  use Telegex.Chain

  require Logger

  alias TelegramApi.Context
  alias TelegramApi.Marzban
  alias TelegramApi.Markdown

  @impl Telegex.Chain
  def handle(%{payload: %{"callback_query" => %{"id" => query_id, "data" => "create_connection:v1"}}} = update, context) do
    Context.answer_callback_query(query_id)

    with {:ok, chat_id} <- Context.get_chat_id(update),
         {:ok, from} <- Context.get_from(update),
         {:ok, username} <- Context.get_username(from) do
      case Context.get_by_username(username) do
        nil ->
          send_error_message(chat_id, "Пользователь не найден. Пожалуйста, выполните /start")

        user ->
          if Enum.empty?(user.marzban_users) do
            create_first_connection(chat_id, user)
          else
            send_already_exists_message(chat_id)
          end
      end
    else
      _ ->
        Logger.error("Could not extract required data from update in RespCreateConnectionChain")
    end

    {:done, context}
  end

  defp create_first_connection(chat_id, user) do
    case Marzban.create_user(user.username) do
      {:ok, marzban_user} ->
        Context.add_marzban_user(user, marzban_user.username)
        send_success_message(chat_id, marzban_user)

      {:error, reason} ->
        Logger.error("Failed to create Marzban user: #{inspect(reason)}")
        send_error_message(chat_id, "Не удалось создать подключение в Marzban.")
    end
  end

  defp send_success_message(chat_id, marzban_user) do
    subscription_url = marzban_user.subscription_url
    qr_code_url = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=#{subscription_url}"

    text =
      ~s("""
      ✅ *Ваше первое подключение создано\!* 

      Используйте QR-код или ссылку ниже для импорта\.

      *Ссылка*:
      `#{Markdown.escape(subscription_url)}`
      """)

    Context.send_photo(chat_id, qr_code_url, caption: text, parse_mode: "MarkdownV2")
  end

  defp send_already_exists_message(chat_id) do
    text =
      ~s("""
      🤔 У вас уже есть активные подключения\.

      Для создания дополнительных используйте кнопку *"➕ Добавить подключение"*\.
      """)

    Context.send_message(chat_id, text, parse_mode: "MarkdownV2")
  end

  defp send_error_message(chat_id, reason) do
    text = "❌ *Ошибка*\n#{Markdown.escape(reason)}"

    payload = %{
      method: "sendMessage",
      chat_id: chat_id,
      text: text,
      parse_mode: "MarkdownV2"
    }

    {:done, %{payload: payload}}
  end
end
