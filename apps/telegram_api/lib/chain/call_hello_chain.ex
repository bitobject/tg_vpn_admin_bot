defmodule TelegramApi.Chain.CallHelloChain do
  @moduledoc """
  Handles a callback query with the 'create_config:' prefix.
  """

  use Telegex.Chain

  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{id: query_id, data: "create_config:" <> _}
        } = _update,
        context
      ) do
    Telegram.answer_callback_query(query_id, text: "Конфигурация создана", show_alert: true)
    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}
end
