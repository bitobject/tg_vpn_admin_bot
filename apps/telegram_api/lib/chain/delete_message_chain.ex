defmodule TelegramApi.Chain.DeleteMessageChain do
  use Telegex.Chain

  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{
            id: query_id,
            data: "delete_message:v1",
            message: %{message_id: message_id}
          }
        } = update,
        context
      ) do
    Telegram.answer_callback_query(query_id)

    with {:ok, chat_id} <- Telegram.get_chat_id(update) do
      Telegram.delete_message(chat_id, message_id)
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}
end
