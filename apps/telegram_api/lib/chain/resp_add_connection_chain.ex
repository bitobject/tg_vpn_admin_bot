defmodule TelegramApi.Chain.RespAddConnectionChain do
  use Telegex.Chain

  require Logger

  alias Core.Context, as: CoreContext
  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{id: query_id, data: "add_connection:" <> _}
        } =
          update,
        context
      ) do
    Telegram.answer_callback_query(query_id)

    case Telegram.get_chat_id(update) do
      {:ok, chat_id} ->
        Task.start(fn ->
          tariffs = CoreContext.list_active_tariffs()
          send_tariffs_message(chat_id, tariffs)
        end)

      _ ->
        Logger.error("Could not extract chat_id in RespAddConnectionChain: #{inspect(update)}")
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  defp send_tariffs_message(chat_id, tariffs) do
    text = "Выберите тариф для нового подключения:"

    keyboard = %{
      inline_keyboard: [
        Enum.map(tariffs, fn tariff ->
          %{
            text: "#{tariff.name} - #{tariff.price} руб.",
            callback_data: "create_connection:#{tariff.id}"
          }
        end)
      ]
    }

    Telegram.send_message(chat_id, text, reply_markup: keyboard)
  end
end
