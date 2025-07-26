defmodule TelegramApi.RespStartChain do
  @moduledoc false

  use Telegex.Chain, {:command, :start}

  require Logger

  alias Telegex.Type.{InlineKeyboardMarkup, InlineKeyboardButton}
  alias TelegramContext

  @impl true
  def match?(%{text: text, chat: %{type: "private"}}, _context) when text != nil do
    String.starts_with?(text, @command)
  end

  @impl true
  def match?(_message, _context), do: false

  @impl true
  def handle(%{from: from, chat: chat, text: _text} = _message, context) do
    Logger.error("User #{from.username} started the bot")

    if is_nil(from.username) or from.username == "" do
      Logger.error(" i am in 1")
      handle_missing_username(chat.id, context)
    else
      Logger.error(" i am in 2")
      attrs = telegram_user_attrs(from)

      case TelegramContext.create_or_update_user(attrs) do
        {:ok, user} ->
          Logger.error("#{user.username} started the bot")
          Logger.error(" i am in 3")

          markup = %InlineKeyboardMarkup{
            inline_keyboard: [
              [
                %InlineKeyboardButton{
                  text: "Hello #{user.first_name || user.username}",
                  callback_data: "hello:v1"
                }
              ]
            ]
          }
          Logger.error(" i am in 4")

          send_hello = %{
            method: "sendMessage",
            chat_id: chat.id,
            text: "Hi, #{user.first_name || user.username}!\nWelcome to our bot.",
            reply_markup: markup,
            parse_mode: "MarkdownV2",
            disable_web_page_preview: true
          }
          Logger.error(" i am in 5")
          context = %{context | payload: send_hello}
          {:done, context}

        {:error, changeset} ->
          Logger.error(" i am in 6")
          Logger.error("Error saving user on /start: #{inspect(changeset)}")
          {:done, %{context | payload: "Что-то пошло не так напишите /support"}}
      end
    end

    Logger.error(" i am in 7")

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: "Hello",
            callback_data: "hello:v1"
          }
        ]
      ]
    }

    send_hello = %{
      method: "sendMessage",
      chat_id: chat.id,
      text:
        "*Hello*#{from.first_name || from.username}",
      reply_markup: markup,
      parse_mode: "MarkdownV2",
      disable_web_page_preview: true
    }

    context = %{context | payload: send_hello}

    {:done, context}
  end

  defp handle_missing_username(chat_id, context) do
    text = """
    Welcome\!

    To use this bot, you need to set a public *username* in your Telegram settings\.
    Please go to `Settings -> Edit profile -> Username` and set one up\.

    Then come back and type /start again\.
    """

    payload = %{
      method: "sendMessage",
      chat_id: chat_id,
      text: text,
      parse_mode: "MarkdownV2"
    }

    {:done, %{context | payload: payload}}
  end

  defp telegram_user_attrs(user_struct) do
    # Convert the Telegex.Type.User struct to a map of attributes
    # suitable for our Ecto changeset.
    Map.from_struct(user_struct)
  end
end
