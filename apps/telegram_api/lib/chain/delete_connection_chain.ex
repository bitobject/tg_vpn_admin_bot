defmodule TelegramApi.Chain.DeleteConnectionChain do
  use Telegex.Chain

  alias TelegramApi.Telegram

  alias Core.Context, as: CoreContext
  alias TelegramApi.Marzban

  require Logger

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{
            id: query_id,
            data: "delete_connection:" <> username,
            message: %{message_id: message_id}
          }
        } = update,
        context
      ) do
    Logger.info("DeleteConnectionChain triggered for user: #{username}")
    Telegram.answer_callback_query(query_id)

    with {:ok, chat_id} <- Telegram.get_chat_id(update),
         {:ok, from} <- Telegram.get_from(update) do
      Task.start(fn ->
        case Marzban.remove_user(username) do
          :ok ->
            handle_successful_deletion(chat_id, message_id, from, username)

          {:ok, _} ->
            handle_successful_deletion(chat_id, message_id, from, username)

          {:error, reason} ->
            handle_error(chat_id, message_id, username, reason)
        end
      end)
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  defp handle_successful_deletion(chat_id, message_id, from, username) do
    # Delete from our DB and then show the personal account
    case CoreContext.get_user_by_telegram_id(from.id) do
      nil ->
        Logger.error("User not found in DB while trying to delete connection: #{from.id}")
        text = "Не удалось отобразить личный кабинет. Пользователь не найден."
        Telegram.edit_message_text(chat_id, message_id, text)

      user ->
        # First, remove the connection from the user
        CoreContext.remove_marzban_user_from_user(user, username)
        # Then, fetch the updated user to get the correct connection list
        updated_user = CoreContext.get_user_by_telegram_id(from.id)

        {text, keyboard} =
          TelegramApi.Chain.ConnectionHelper.build_personal_account_content(updated_user)

        Telegram.edit_message_text(chat_id, message_id, text, reply_markup: keyboard)
    end
  end

  defp handle_error(chat_id, message_id, username, reason) do
    Logger.error("Failed to delete user from Marzban: #{inspect(reason)}")

    text =
      "Не удалось удалить подключение `#{username}`. Пожалуйста, попробуйте еще раз или обратитесь в поддержку."

    keyboard = %{
      inline_keyboard: [
        [%{text: "⬅️ Назад", callback_data: "show_connection_link:#{username}:edit"}]
      ]
    }

    Telegram.edit_message_text(chat_id, message_id, text,
      parse_mode: "Markdown",
      reply_markup: keyboard
    )
  end
end
