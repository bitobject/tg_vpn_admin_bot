defmodule TelegramApi.Chain.PersonalAccountChain do
  @moduledoc """
  Handles the 'Personal Account' button press.
  """

  use Telegex.Chain

  require Logger

  alias Core.Context, as: CoreContext
  alias TelegramApi.Chain.ConnectionHelper
  alias TelegramApi.Context

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{id: query_id, data: "personal_account:v1"}
        } = update,
        context
      ) do
    Context.answer_callback_query(query_id)

    with {:ok, chat_id} <- Context.get_chat_id(update),
         {:ok, from} <- Context.get_from(update) do
      Task.start(fn ->
        case CoreContext.get_user_by_telegram_id(from.id) do
          nil ->
            Context.send_message(chat_id, "Пользователь не найден. Пожалуйста, нажмите /start")

          user ->
            ConnectionHelper.process_user_connections(chat_id, user)
        end
      end)
    else
      error ->
        Logger.error(
          "Could not extract required data from update in PersonalAccountChain: #{inspect(error)}"
        )
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}
end
