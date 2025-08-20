defmodule TelegramApi.Chain.ShowConnectionLinkChain do
  use Telegex.Chain

  require Logger

  alias TelegramApi.Marzban
  alias TelegramApi.Telegram
  alias TelegramApi.State
  alias TelegramApi.Chain.ConnectionHelper

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{
            id: query_id,
            data: "show_connection_link:" <> data,
            message: %{message_id: message_id}
          }
        } = update,
        context
      ) do
    Telegram.answer_callback_query(query_id)

    [username, mode] =
      case String.split(data, ":", parts: 2) do
        [u] -> [u, nil]
        [u, m] -> [u, m]
      end

    with {:ok, chat_id} <- Telegram.get_chat_id(update) do
      Task.start(fn ->
        case Marzban.get_user(username) do
          {:ok, marzban_user} ->
            {text, keyboard} = build_connection_link_content(marzban_user)

            case mode do
              "edit" ->
                edit_connection_link_message(chat_id, message_id, text, keyboard)

              _ ->
                send_connection_link_message(chat_id, text, keyboard)
            end

          {:error, reason} ->
            Logger.error(
              "Failed to get user from Marzban in ShowConnectionLinkChain: #{inspect(reason)}"
            )
        end
      end)
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  def build_connection_link_content(marzban_user) do
    username = marzban_user["username"]
    subscription_url = marzban_user["subscription_url"]
    status = ConnectionHelper.format_status(marzban_user["status"])
    expire_date = ConnectionHelper.format_expire_date(marzban_user["expire"])

    text = """
    *Подключение:* `#{username}`
    *Статус:* #{status}
    *Действует до:* #{expire_date}

    *Ваша ссылка:*
    `#{marzban_base_url()}#{subscription_url}`
    """

    keyboard = %{
      inline_keyboard: [
        [
          %{text: "Оплатить/Продлить", callback_data: "view_tariffs:#{username}"},
          %{text: "Удалить 🗑️", callback_data: "confirm_delete_connection:#{username}"}
        ]
      ]
    }

    {text, keyboard}
  end

  defp send_connection_link_message(chat_id, text, keyboard) do
    case Telegram.send_message(chat_id, text, parse_mode: "Markdown", reply_markup: keyboard) do
      {:ok, %{message_id: new_message_id}} ->
        State.set_last_message_id(chat_id, new_message_id)

      {:error, reason} ->
        Logger.error("Failed to send connection link message: #{inspect(reason)}")
    end
  end

  defp edit_connection_link_message(chat_id, message_id, text, keyboard) do
    case Telegram.edit_message_text(chat_id, message_id, text,
           parse_mode: "Markdown",
           reply_markup: keyboard
         ) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to edit connection link message: #{inspect(reason)}")
    end
  end

  defp marzban_base_url do
    Application.get_env(:telegram_api, :marzban)[:base_url]
  end
end
