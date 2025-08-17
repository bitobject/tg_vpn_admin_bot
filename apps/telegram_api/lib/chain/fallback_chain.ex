defmodule TelegramApi.Chain.FallbackChain do
  @moduledoc """
  A fallback chain that handles any text message that was not handled by other chains.
  """

  use Telegex.Chain

  require Logger

  alias TelegramApi.Context

  @impl Telegex.Chain
  def handle(%Telegex.Type.Update{message: %Telegex.Type.Message{text: _text}} = update, context) do
    with {:ok, chat_id} <- Context.get_chat_id(update) do
      Task.start(fn ->
        response_text = "Я не понимаю эту команду. Пожалуйста, воспользуйтесь кнопками в меню."
        Context.send_message(chat_id, response_text)
      end)
    else
      error ->
        Logger.error("Could not extract chat_id in FallbackChain: #{inspect(error)}")
    end

    {:stop, context}
  end

  # Catch any other update that falls through and stop the chain
  def handle(_update, context), do: {:stop, context}
end
