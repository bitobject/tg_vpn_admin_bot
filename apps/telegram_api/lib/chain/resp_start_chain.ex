defmodule TelegramApi.Chain.RespStartChain do
  use Telegex.Chain

  require Logger

  alias Core.Context, as: CoreContext
  alias TelegramApi.Telegram

  @impl Telegex.Chain
  def handle(%{message: %Telegex.Type.Message{text: "/start"}} = update, context) do
    with {:ok, chat_id} <- Telegram.get_chat_id(update),
         {:ok, from} <- Telegram.get_from(update),
         {:ok, username} <- Telegram.get_username(from) do
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
            send_welcome_message(chat_id, user)

          {:error, changeset} ->
            Logger.error(
              "Failed to create or update user in RespStartChain: #{inspect(changeset)}"
            )
        end
      end)
    else
      error ->
        Logger.error(
          "Could not extract required data from update in RespStartChain: #{inspect(error)}"
        )
    end

    {:stop, context}
  end

  def handle(_update, context), do: {:ok, context}

  defp send_welcome_message(chat_id, user) do
    text = welcome_text(user)
    keyboard = main_keyboard()

    Telegram.send_message(chat_id, text, parse_mode: "Markdown", reply_markup: keyboard)
  end

  defp welcome_text(user) do
    if user.inserted_at == user.updated_at do
      """
      👋 *Добро пожаловать, #{user.first_name}!*

      Это бот для управления вашими VPN-подключениями.

      Воспользуйтесь кнопками ниже для навигации.
      """
    else
      """
      👋 *С возвращением, #{user.first_name}!*

      Рад снова вас видеть. Воспользуйтесь кнопками ниже для навигации.
      """
    end
  end

  defp main_keyboard do
    %{
      keyboard: [
        [%{text: "Личный кабинет 💼"}],
        [%{text: "Инструкция 📖", url: "https://google.com"}, %{text: "Поддержка 🆘"}]
      ],
      resize_keyboard: true,
      one_time_keyboard: false
    }
  end
end
