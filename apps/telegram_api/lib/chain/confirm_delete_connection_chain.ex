defmodule TelegramApi.Chain.ConfirmDeleteConnectionChain do
  use Telegex.Chain

  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{
            id: query_id,
            data: "confirm_delete_connection:" <> username,
            message: %{message_id: message_id}
          }
        } = update,
        context
      ) do
    Telegram.answer_callback_query(query_id)

    with {:ok, chat_id} <- Telegram.get_chat_id(update) do
      text = """
      ⚠️ *Вы уверены, что хотите удалить подключение `#{username}`?*

      Это действие необратимо. Все данные, связанные с этим подключением, будут удалены.
      """

      keyboard = %{
        inline_keyboard: [
          [
            %{text: "Да, удалить", callback_data: "delete_connection:#{username}"},
            %{text: "Отмена", callback_data: "show_connection_link:#{username}:edit"}
          ]
        ]
      }

      Telegram.edit_message_text(chat_id, message_id, text,
        parse_mode: "Markdown",
        reply_markup: keyboard
      )
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}
end
