defmodule TelegramApi.Chain.PersonalAccountChain do
  @moduledoc """
  Handles the 'Personal Account' button press.
  """

  use Telegex.Chain

  require Logger

  alias Core.Context, as: CoreContext
  alias TelegramApi.Chain.ConnectionHelper
  alias TelegramApi.Telegram
  alias TelegramApi.State

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{id: query_id, data: "personal_account:v1"}
        } = update,
        context
      ) do
    Telegram.answer_callback_query(query_id)
    process_request(update, context)
  end

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          message: %Telegex.Type.Message{text: "Личный кабинет 💼"}
        } = update,
        context
      ) do
    process_request(update, context)
  end

  def handle(_update, context), do: {:ok, context}

  defp process_request(%Telegex.Type.Update{message: _} = update, context) do
    # User sent a text message "Личный кабинет 💼"
    with {:ok, chat_id} <- Telegram.get_chat_id(update),
         {:ok, %{id: telegram_id}} <- Telegram.get_from(update) do
      State.delete_qr_message_id(chat_id)

      # Send a temporary message and then edit it
      with {:ok, %Telegex.Type.Message{message_id: message_id}} <-
             Telegram.send_message(chat_id, "Загружаю информацию о ваших подключениях...") do
        start_user_lookup_task(chat_id, message_id, telegram_id)
      end
    end

    {:stop, context}
  end

  defp process_request(
         %Telegex.Type.Update{callback_query: %{message: %{message_id: message_id}}} = update,
         context
       ) do
    # User pressed an inline button
    with {:ok, chat_id} <- Telegram.get_chat_id(update),
         {:ok, %{id: telegram_id}} <- Telegram.get_from(update) do
      State.delete_qr_message_id(chat_id)

      # Edit the existing message directly
      start_user_lookup_task(chat_id, message_id, telegram_id)
    end

    {:stop, context}
  end

  defp start_user_lookup_task(chat_id, message_id, telegram_id) do
    Task.Supervisor.start_child(
      TelegramApi.TaskSupervisor,
      fn -> __MODULE__.run_async_user_lookup(chat_id, message_id, telegram_id) end
    )
  end

  def run_async_user_lookup(chat_id, message_id, telegram_id) do
    try do
      IO.inspect(telegram_id, label: "[PersonalAccountChain] Task started for user ID")
      Logger.info("Task started for user ID: #{telegram_id}")

      case CoreContext.get_user_by_telegram_id(telegram_id) do
        nil ->
          IO.inspect(telegram_id, label: "[PersonalAccountChain] User not found in DB")
          Logger.warning("User with telegram_id #{telegram_id} not found in DB.")

          Telegram.edit_message_text(
            chat_id,
            message_id,
            "Пользователь не найден. Пожалуйста, нажмите /start"
          )

        user ->
          IO.inspect(user, label: "[PersonalAccountChain] User found, calling ConnectionHelper")
          Logger.info("User found, processing connections for user: #{user.telegram_id}")
          ConnectionHelper.process_user_connections(chat_id, user, message_id)
      end
    catch
      kind, reason ->
        stacktrace = __STACKTRACE__
        IO.inspect({kind, reason, stacktrace}, label: "[PersonalAccountChain] CRASH IN TASK")

        Logger.error(
          "Error in PersonalAccountChain Task: #{kind}: #{inspect(reason)}\nStacktrace: #{inspect(stacktrace)}"
        )
    end
  end
end
