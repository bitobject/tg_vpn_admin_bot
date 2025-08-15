defmodule TelegramApi.Chain.EchoTextChain do
  @moduledoc """
  A simple chain that echoes any text message back to the user in a private chat.
  """

  use Telegex.Chain

  alias TelegramApi.Context

  @impl Telegex.Chain
  def handle(%{payload: %{"message" => %{"text" => text, "chat" => %{"id" => chat_id, "type" => "private"}}}} = update, context) 
    when is_binary(text) do
    if String.starts_with?(text, "/") do
      {:next, update, context}
    else
      Context.send_message(chat_id, text)
      {:done, context}
    end
  end


end
