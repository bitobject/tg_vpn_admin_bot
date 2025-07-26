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
  def handle(%{from: from, chat: chat} = _message, context) do
    Logger.error("from:  #{inspect(from)}")
    attrs = telegram_user_attrs(from)

    case TelegramContext.create_or_update_user(attrs) do
      {:ok, user} ->
        Logger.error("user:  #{inspect(user)}")

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

        text = """
        *Hi, #{user.first_name}!*\n
        Welcome to our bot\.
        😇 You can learn more from here: [telegex/telegex](https://github.com/telegex/telegex)\
        """

        send_hello = %{
          method: "sendMessage",
          chat_id: chat.id,
          text: text,
          reply_markup: markup,
          parse_mode: "MarkdownV2",
          disable_web_page_preview: true
        }

        new_context =
          context
          |> Map.put(:payload, send_hello)
          |> Map.put(:current_user, user)

        {:done, new_context}

      {:error, changeset} ->
        Logger.error("Error saving user on /start: #{inspect(changeset)}")
        {:halt, context}
    end
  end

  defp telegram_user_attrs(from) do
    # The 'from' map has string keys. We extract only the fields that are present.
    attrs = %{
      "id" => from["id"],
      "is_bot" => from["is_bot"],
      "first_name" => from["first_name"],
      "last_name" => from["last_name"],
      "username" => from["username"],
      "language_code" => from["language_code"],
      "is_premium" => from["is_premium"],
      "added_to_attachment_menu" => from["added_to_attachment_menu"]
    }

    # Convert string keys to atoms and filter out nil values
    attrs
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      if !is_nil(value) do
        Map.put(acc, String.to_atom(key), value)
      else
        acc
      end
    end)
  end
end
