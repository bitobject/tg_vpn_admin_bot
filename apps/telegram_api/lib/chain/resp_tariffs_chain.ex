defmodule TelegramApi.Chain.RespTariffsChain do
  @moduledoc false
  use Telegex.Chain

  require Logger

  alias Core.Context
  alias Core.Schemas.Tariff
  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{message: %Telegex.Type.Message{text: "/tariffs"}} = update,
        context
      ) do
    with {:ok, chat_id} <- Telegram.get_chat_id(update) do
      Task.start(fn ->
        tariffs = Context.list_active_tariffs()
        send_tariffs_for_creation(chat_id, tariffs)
      end)
    else
      error ->
        Logger.error("Could not extract chat_id in RespTariffsChain: #{inspect(error)}")
    end

    {:stop, context}
  end

  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{id: query_id, data: "view_tariffs:" <> username}
        } = update,
        context
      ) do
    Telegram.answer_callback_query(query_id)

    with {:ok, chat_id} <- Telegram.get_chat_id(update) do
      Task.start(fn ->
        tariffs = Context.list_active_tariffs()
        send_tariffs_for_payment(chat_id, tariffs, username)
      end)
    else
      error ->
        Logger.error("Could not extract chat_id in RespTariffsChain: #{inspect(error)}")
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  # --- Private Helpers ---

  defp send_tariffs_for_creation(chat_id, []) do
    Telegram.send_message(chat_id, "К сожалению, в данный момент нет доступных тарифов.")
  end

  defp send_tariffs_for_creation(chat_id, tariffs) do
    text = "Выберите тариф для нового подключения:"

    keyboard =[[%{
      inline_keyboard: Enum.map(tariffs, &tariff_to_creation_button/1)
    }]]

    Telegram.send_message(chat_id, text, reply_markup: keyboard)
  end

  defp send_tariffs_for_payment(chat_id, [], _username) do
    Telegram.send_message(chat_id, "К сожалению, в данный момент нет доступных тарифов.")
  end

  defp send_tariffs_for_payment(chat_id, tariffs, username) do
    text = "Выберите тариф для продления или оплаты:"

    keyboard =[[%{
      inline_keyboard: Enum.map(tariffs, &tariff_to_payment_button(&1, username))
    }]]

    Telegram.send_message(chat_id, text, reply_markup: keyboard)
  end

  defp tariff_to_creation_button(%Tariff{} = tariff) do
    [
      %{text: "#{tariff.name} - #{tariff.price}₽", callback_data: "create_connection:#{tariff.id}"}
    ]
  end

  defp tariff_to_payment_button(%Tariff{} = tariff, username) do
    [
      %{text: "#{tariff.name} - #{tariff.price}₽", callback_data: "pay_tariff:#{tariff.id}:#{username}"}
    ]
  end
end
