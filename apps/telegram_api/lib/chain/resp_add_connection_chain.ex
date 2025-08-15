defmodule TelegramApi.Chain.RespAddConnectionChain do
  use Telegex.Chain

  require Logger

  alias TelegramApi.Context
  alias TelegramApi.Marzban
  alias TelegramApi.Markdown

  @impl Telegex.Chain
  def handle(%{payload: %{"callback_query" => %{"id" => query_id, "data" => "add_connection:v1"}}} = update, context) do
    Context.answer_callback_query(query_id)

    with {:ok, chat_id} <- Context.get_chat_id(update),
         {:ok, from} <- Context.get_from(update),
         {:ok, username} <- Context.get_username(from) do
      case Context.get_by_username(username) do
        nil ->
          send_error_message(chat_id, "Пользователь не найден. Пожалуйста, выполните /start")

        user ->
          if Enum.empty?(user.marzban_users) do
            send_no_base_user_message(chat_id)
          else
            create_additional_connection(chat_id, user)
          end
      end
    else
      _ ->
        Logger.error("Could not extract required data from update in RespAddConnectionChain")
    end

    {:done, context}
  end

  defp create_additional_connection(chat_id, user) do
    base_username = user.username

    with {:ok, next_username} <- Marzban.get_next_username_for(base_username),
         {:ok, new_marzban_user} <- Marzban.create_user(next_username) do
      Context.add_marzban_user(user, new_marzban_user["username"])
      send_success_message(chat_id, new_marzban_user)
    else
      {:error, :conflict} ->
        Logger.error("Conflict when creating additional Marzban user with a generated name.")
        send_error_message(chat_id, "Произошла ошибка. Попробуйте еще раз.")

      {:error, reason} ->
        Logger.error("Failed to create additional Marzban user: #{inspect(reason)}")
        send_error_message(chat_id, "Не удалось создать дополнительное подключение.")
    end
  end

  defp send_success_message(chat_id, marzban_user) do
    subscription_url = marzban_user.subscription_url
    qr_code_url = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=#{subscription_url}"

    text =
      ~s("""
      ✅ *Новое подключение создано\!* 

      Используйте QR-код или ссылку ниже для импорта\.

      *Ссылка*:
      `#{Markdown.escape(subscription_url)}`
      """)

    Context.send_photo(chat_id, qr_code_url, caption: text, parse_mode: "MarkdownV2")
  end

  defp send_no_base_user_message(chat_id) do
    text =
      ~s("""
      🤔 У вас еще нет основного подключения. 

      Пожалуйста, сначала нажмите кнопку *"Создать подключение"*\.
      """)

    Context.send_message(chat_id, text, parse_mode: "MarkdownV2")
  end

  defp send_error_message(chat_id, reason) do
    text = "❌ *Ошибка*\n#{Markdown.escape(reason)}"
    Context.send_message(chat_id, text, parse_mode: "MarkdownV2")
  end
end
