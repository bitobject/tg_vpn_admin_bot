defmodule TelegramApi.Chain.RespCreateConnectionChain do
  use Telegex.Chain

  require Logger

  alias Core.Context, as: CoreContext
  alias TelegramApi.Chain.ConnectionHelper
  alias TelegramApi.Context

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{
            id: query_id,
            data: "create_connection:" <> tariff_id_str
          }
        } = update,
        context
      ) do
    Context.answer_callback_query(query_id)
    tariff_id = String.to_integer(tariff_id_str)

    with {:ok, chat_id} <- Context.get_chat_id(update),
         {:ok, from} <- Context.get_from(update),
         {:ok, username} <- Context.get_username(from) do
      Task.start(fn ->
        user = CoreContext.get_or_create_user(%{telegram_id: from.id, username: username})
        process_connection_creation(chat_id, user, tariff_id)
      end)
    else
      error ->
        Logger.error(
          "Could not extract required data from update in RespCreateConnectionChain: #{inspect(error)}"
        )
    end

    {:stop, context}
  end

  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{id: query_id, data: "create_connection:v1"}
        } = update,
        context
      ) do
    Context.answer_callback_query(query_id)

    with {:ok, chat_id} <- Context.get_chat_id(update) do
      tariffs = CoreContext.list_active_tariffs()

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

      Context.send_message(chat_id, "Выберите тариф для нового подключения:",
        reply_markup: keyboard
      )
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  defp process_connection_creation(chat_id, user, tariff_id) do
    case CoreContext.get_tariff(tariff_id) do
      nil ->
        send_error_message(chat_id, "Тариф не найден. Пожалуйста, попробуйте еще раз.")

      tariff ->
        case ConnectionHelper.create_marzban_user(tariff, user.username) do
          {:ok, marzban_user} ->
            CoreContext.add_marzban_user_to_telegram_user(user, marzban_user["username"])
            send_success_message(chat_id, marzban_user)

          {:error, reason} ->
            Logger.error("Failed to create Marzban user: #{inspect(reason)}")
            send_error_message(chat_id, "Не удалось создать подключение.")
        end
    end
  end

  defp send_success_message(chat_id, marzban_user) do
    Context.send_message(chat_id, "✅ *Ваше новое подключение создано!*", parse_mode: "Markdown")
    details = ConnectionHelper.generate_connection_details(marzban_user)
    ConnectionHelper.send_connection_details(chat_id, details)
  end

  defp send_error_message(chat_id, reason) do
    text = "❌ *Ошибка*\n#{reason}"
    Context.send_message(chat_id, text, parse_mode: "Markdown")
  end
end
