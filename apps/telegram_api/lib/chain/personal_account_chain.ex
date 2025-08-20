defmodule TelegramApi.Chain.PersonalAccountChain do
  @moduledoc """
  Handles the 'Personal Account' button press.
  """

  use Telegex.Chain

  require Logger

  alias Core.Context, as: CoreContext
  alias TelegramApi.Chain.ConnectionHelper
  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          message: %Telegex.Type.Message{text: "Личный кабинет 💼"}
        } = update,
        context
      ) do
    process_request(update, context)
  end

  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{id: query_id, data: "personal_account"}
        } = update,
        context
      ) do
    Telegram.answer_callback_query(query_id)
    process_request(update, context)
  end

  def handle(_update, context), do: {:ok, context}

  defp process_request(update, context) do
    with {:ok, chat_id} <- Telegram.get_chat_id(update),
         {:ok, %{id: telegram_id}} <- Telegram.get_from(update) do
      # Send a "loading" message first
      {:ok, %{message_id: loading_message_id}} =
        Telegram.send_message(chat_id, "Загружаю информацию...")

      # Start a task to do the work and then edit the message
      Task.start(fn ->
        run_user_lookup_and_update_message(telegram_id, chat_id, loading_message_id)
      end)
    end

    {:stop, context}
  end

  defp run_user_lookup_and_update_message(telegram_id, chat_id, loading_message_id) do
    case CoreContext.get_user_by_telegram_id(telegram_id) do
      nil ->
        Telegram.edit_message_text(
          chat_id,
          loading_message_id,
          "Пользователь не найден. Пожалуйста, нажмите /start"
        )

      user ->
        {text, keyboard} = ConnectionHelper.build_personal_account_content(user)

        # It's better to delete the loading message and send a new one to bring it to the user's attention.
        Telegram.delete_message(chat_id, loading_message_id)
        Telegram.send_message(chat_id, text, reply_markup: keyboard)
    end
  end
end
