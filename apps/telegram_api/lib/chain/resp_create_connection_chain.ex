defmodule TelegramApi.Chain.RespCreateConnectionChain do
  use Telegex.Chain

  require Logger

  alias Core.Context, as: CoreContext
  alias TelegramApi.Chain.ConnectionHelper
  alias TelegramApi.Chain.ShowConnectionLinkChain
  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{
            id: query_id,
            data: "create_connection:" <> tariff_id_str,
            message: %{message_id: message_id}
          }
        } = update,
        context
      ) do
    Telegram.answer_callback_query(query_id)
    tariff_id = String.to_integer(tariff_id_str)

    with {:ok, chat_id} <- Telegram.get_chat_id(update),
         {:ok, from} <- Telegram.get_from(update),
         {:ok, username} <- Telegram.get_username(from) do
      Logger.info(
        "[RespCreateConnectionChain] Received callback to create connection for tariff #{tariff_id_str} from user #{username}"
      )

      Task.start(fn ->
        attrs = %{
          telegram_id: from.id,
          username: username,
          first_name: from.first_name,
          last_name: from.last_name,
          language_code: from.language_code,
          is_bot: from.is_bot
        }

        case CoreContext.create_or_update_user(attrs) do
          {:ok, user} ->
            process_connection_creation(chat_id, message_id, user, tariff_id)

          {:error, changeset} ->
            Logger.error("Failed to create or update user: #{inspect(changeset)}")
            send_error_message(chat_id, "Не удалось обработать ваш профиль. Попробуйте позже.")
        end
      end)
    else
      error ->
        Logger.error(
          "Could not extract required data from update in RespCreateConnectionChain: #{inspect(error)}"
        )
    end

    {:stop, context}
  end

  def handle(
        %Telegex.Type.Update{
          callback_query: %Telegex.Type.CallbackQuery{id: query_id, data: "create_connection:v1"}
        } = update,
        context
      ) do
    Telegram.answer_callback_query(query_id)

    with {:ok, chat_id} <- Telegram.get_chat_id(update) do
      tariffs = CoreContext.list_active_tariffs()

      keyboard = %{
        inline_keyboard: [
          Enum.map(tariffs, fn tariff ->
            %{
              text: "#{tariff.name} - #{tariff.price} руб.",
              callback_data: "create_connection:#{tariff.id}"
            }
          end)
        ]
      }

      Telegram.send_message(chat_id, "Выберите тариф для нового подключения:",
        reply_markup: keyboard
      )
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  defp process_connection_creation(chat_id, message_id, user, tariff_id) do
    Logger.info(
      "[RespCreateConnectionChain] Processing connection creation for user #{user.username} and tariff #{tariff_id}"
    )

    case CoreContext.get_tariff(tariff_id) do
      nil ->
        send_error_message(chat_id, "Тариф не найден. Пожалуйста, попробуйте еще раз.")

      tariff ->
        Logger.info(
          "[RespCreateConnectionChain] Creating Marzban user for #{user.username} with tariff #{tariff.name}"
        )

        case ConnectionHelper.create_marzban_user(tariff, user.username) do
          {:ok, marzban_user} ->
            Logger.info(
              "[RespCreateConnectionChain] Marzban user #{marzban_user["username"]} created successfully. Adding to telegram user #{user.username}."
            )

            CoreContext.add_marzban_user_to_telegram_user(user, marzban_user["username"])
            send_success_message(chat_id, message_id, marzban_user)

          {:error, reason} ->
            Logger.error("Failed to create Marzban user: #{inspect(reason)}")
            send_error_message(chat_id, "Не удалось создать подключение.")
        end
    end
  end

  defp send_success_message(chat_id, message_id, marzban_user) do
    Logger.info(
      "[RespCreateConnectionChain] Sending success message for #{marzban_user["username"]}"
    )

    # Delete the message with the tariff list
    Telegram.delete_message(chat_id, message_id)

    # Send a new message with the connection details
    {text, keyboard} = ShowConnectionLinkChain.build_connection_link_content(marzban_user)
    Telegram.send_message(chat_id, text, parse_mode: "Markdown", reply_markup: keyboard)
  end

  defp send_error_message(chat_id, reason) do
    text = "❌ *Ошибка*\n#{reason}"
    Telegram.send_message(chat_id, text, parse_mode: "Markdown")
  end
end
