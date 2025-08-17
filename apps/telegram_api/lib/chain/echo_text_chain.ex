defmodule TelegramApi.Chain.EchoTextChain do
  @moduledoc """
  A simple chain that echoes any text message back to the user in a private chat.
  """

  use Telegex.Chain

  alias TelegramApi.Telegram

  require Logger

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{message: %Telegex.Type.Message{text: text, chat: %{type: "private"}}} =
          update,
        context
      ) do
    # Ignore commands
    if String.starts_with?(text, "/") do
      {:next, context}
    else
      with {:ok, chat_id} <- Telegram.get_chat_id(update) do
        Task.start(fn -> Telegram.send_message(chat_id, text) end)
      else
        error ->
          Logger.error("Could not extract chat_id in EchoTextChain: #{inspect(error)}")
      end

      {:stop, context}
    end
  end

  def handle(_update, context), do: {:next, context}
end
