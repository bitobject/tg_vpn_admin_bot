defmodule TelegramApi.Chain.RespStartChain do
  use Telegex.Chain

  require Logger

  alias TelegramApi.Context
  alias Core.Context, as: CoreContext

  @impl Telegex.Chain
  def handle(%{message: %Telegex.Type.Message{text: "/start"}} = update, context) do
    with {:ok, chat_id} <- Context.get_chat_id(update),
         {:ok, from} <- Context.get_from(update),
         {:ok, username} <- Context.get_username(from) do
      # This Task.start is optional but good practice to not block the chain
      Task.start(fn ->
        user = CoreContext.get_or_create_user(%{telegram_id: from.id, username: username})
        send_welcome_message(chat_id, user)
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
    if Enum.empty?(user.marzban_users) do
      # User has NO connections
      text =
        """
        👋 *Добро пожаловать, #{user.username}!*

        Это бот для управления вашими подключениями к VPN.

        У вас еще нет активных подключений.
        Нажмите *Создать подключение*, чтобы получить ваш первый доступ.
        """

      keyboard = %{
        inline_keyboard: [
          [%{text: "Создать подключение", callback_data: "add_connection:v1"}]
        ]
      }

      Context.send_message(chat_id, text, parse_mode: "Markdown", reply_markup: keyboard)
    else
      # User HAS connections
      connections_list =
        user.marzban_users
        |> Enum.map(&"  - `#{&1}`")
        |> Enum.join("\n")

      text =
        """
        👋 *С возвращением, #{user.username}!*

        Ваши активные подключения:
        #{connections_list}

        Вы можете добавить еще одно или перейти в личный кабинет.
        """

      keyboard = %{
        inline_keyboard: [
          [
            %{text: "➕ Добавить подключение", callback_data: "add_connection:v1"},
            %{text: "Личный кабинет", callback_data: "personal_account:v1"}
          ]
        ]
      }

      Context.send_message(chat_id, text, parse_mode: "Markdown", reply_markup: keyboard)
    end
  end
end
