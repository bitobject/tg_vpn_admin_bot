defmodule TelegramApi.Chain.FallbackChain do
  @moduledoc """
  A fallback chain that handles any text message that was not handled by other chains.
  """

  use Telegex.Chain

  alias TelegramApi.Context

  @impl Telegex.Chain
  def handle(%{message: %Telegex.Type.Message{text: _text}} = update, context) do
    with {:ok, chat_id} <- Context.get_chat_id(update) do
      response_text = "Я не понимаю эту команду. Пожалуйста, воспользуйтесь кнопками в меню."
      Context.send_message(chat_id, response_text)
    end

    {:done, context}
  end
end
