defmodule TelegramApi.Chain.RespTariffsChain do
  @moduledoc false
  use Telegex.Chain

  require Logger

  alias Core.Context
  alias Core.Schemas.Tariff
  alias TelegramApi.Context, as: ApiContext

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{message: %Telegex.Type.Message{text: "/tariffs"}} = update,
        context
      ) do
    with {:ok, chat_id} <- ApiContext.get_chat_id(update) do
      Task.start(fn ->
        tariffs = Context.list_active_tariffs()
        send_tariffs_message(chat_id, tariffs)
      end)
    else
      error ->
        Logger.error("Could not extract chat_id in RespTariffsChain: #{inspect(error)}")
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  # --- Private Helpers ---

  defp send_tariffs_message(chat_id, []) do
    ApiContext.send_message(chat_id, "К сожалению, в данный момент нет доступных тарифов.")
  end

  defp send_tariffs_message(chat_id, tariffs) do
    text = "Выберите подходящий тариф:"

    keyboard = %{
      inline_keyboard: Enum.map(tariffs, &tariff_to_button/1)
    }

    ApiContext.send_message(chat_id, text, reply_markup: keyboard)
  end

  defp tariff_to_button(%Tariff{} = tariff) do
    [
      %{text: "#{tariff.name} - #{tariff.price}₽", callback_data: "pay_tariff_#{tariff.id}"}
    ]
  end
end
