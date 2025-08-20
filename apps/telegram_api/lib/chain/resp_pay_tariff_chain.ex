defmodule TelegramApi.Chain.RespPayTariffChain do
  use Telegex.Chain

  require Logger

  alias Core.Context, as: CoreContext
  alias TelegramApi.Chain.ConnectionHelper
  alias TelegramApi.Marzban
  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{
            id: query_id,
            data: "pay_tariff:" <> payload
          }
        } =
          update,
        context
      ) do
    Telegram.answer_callback_query(query_id)

    case Telegram.get_chat_id(update) do
      {:ok, chat_id} ->
        with [tariff_id_str, username] <- String.split(payload, ":", parts: 2),
             {:ok, tariff_id} <- safe_to_integer(tariff_id_str) do
          Task.start(fn ->
            process_payment(chat_id, tariff_id, username)
          end)
        else
          _ ->
            Logger.error(
              "Invalid payload in RespPayTariffChain: #{inspect(update.callback_query.data)}"
            )

            send_error_message(
              chat_id,
              "Произошла внутренняя ошибка. Пожалуйста, попробуйте еще раз."
            )
        end

      _ ->
        Logger.error("Could not extract chat_id in RespPayTariffChain: #{inspect(update)}")
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  defp process_payment(chat_id, tariff_id, username) do
    with {:ok, tariff} <- get_tariff(tariff_id),
         {:ok, marzban_user} <- Marzban.get_user(username),
         {:ok, updated_marzban_user} <- ConnectionHelper.extend_marzban_user(marzban_user, tariff) do
      send_success_message(chat_id, updated_marzban_user, tariff)
    else
      {:error, :tariff_not_found} ->
        send_error_message(chat_id, "Выбранный тариф не найден.")

      {:error, :user_not_found} ->
        send_error_message(chat_id, "Пользователь подключения не найден.")

      {:error, reason} ->
        Logger.error("Failed to extend Marzban user subscription: #{inspect(reason)}")
        send_error_message(chat_id, "Не удалось продлить подписку.")
    end
  end

  defp get_tariff(tariff_id) do
    case CoreContext.get_tariff(tariff_id) do
      nil -> {:error, :tariff_not_found}
      tariff -> {:ok, tariff}
    end
  end

  defp safe_to_integer(str) do
    try do
      {:ok, String.to_integer(str)}
    rescue
      ArgumentError -> {:error, :invalid_integer}
    end
  end

  defp send_success_message(chat_id, marzban_user, tariff) do
    expire_date_str = ConnectionHelper.format_expire_date(marzban_user["expire"])
    username = marzban_user["username"]

    text = """
    ✅ Подписка "#{tariff.name}" для `#{username}` успешно продлена!

    Новая дата окончания: *#{expire_date_str}*
    """

    Telegram.send_message(chat_id, text, parse_mode: "Markdown")
  end

  defp send_error_message(chat_id, reason) do
    text = "❌ *Ошибка*\n#{reason}"
    Telegram.send_message(chat_id, text, parse_mode: "Markdown")
  end
end
