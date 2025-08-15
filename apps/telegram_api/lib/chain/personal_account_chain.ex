defmodule TelegramApi.Chain.PersonalAccountChain do
  @moduledoc """
  Handles the 'Personal Account' button press.
  """

  use Telegex.Chain

  require Logger

  alias TelegramApi.Context
  alias TelegramApi.Marzban
  alias TelegramApi.Markdown

  @impl Telegex.Chain
  def handle(%{payload: %{"callback_query" => %{"id" => query_id, "data" => "personal_account:v1"}}} = update, context) do
    Context.answer_callback_query(query_id)

    with {:ok, chat_id} <- Context.get_chat_id(update),
         {:ok, from} <- Context.get_from(update),
         {:ok, username} <- Context.get_username(from) do
      case Context.get_by_username(username) do
        nil ->
          Context.send_message(chat_id, "Пользователь не найден. Пожалуйста, нажмите /start")

        user ->
          process_user_connections(chat_id, user)
      end
    else
      _ ->
        Logger.error("Could not extract required data from update in PersonalAccountChain")
    end

    {:done, context}
  end

  defp process_user_connections(chat_id, user) do
    marzban_usernames = user.marzban_users

    if Enum.empty?(marzban_usernames) do
      text = "У вас еще нет активных подключений. Нажмите кнопку 'Создать подключение', чтобы получить свой первый ключ."
      Context.send_message(chat_id, text)
    else
      Context.send_message(chat_id, "Загружаю информацию о ваших подключениях...")

      user_connection_details =
        marzban_usernames
        |> Task.async_stream(&Marzban.get_user/1, timeout: 15000)
        |> Enum.map(fn {:ok, res} -> res end)
        |> Enum.filter(fn
          {:ok, _} ->
            true

          {:error, :not_found} ->
            Logger.warning("User found in local DB but not in Marzban. Needs cleanup.")
            false

          {:error, reason} ->
            Logger.error("Failed to fetch user from Marzban: #{inspect(reason)}")
            false
        end)
        |> Enum.map(fn {:ok, u} -> u end)

      if Enum.empty?(user_connection_details) do
        text = "Не удалось получить информацию о ваших подключениях. Возможно, они были удалены. Попробуйте создать новое."
        Context.send_message(chat_id, text)
      else
        Enum.each(user_connection_details, &send_connection_message(chat_id, &1))
      end
    end
  end

  defp send_connection_message(chat_id, marzban_user) do
    subscription_url = marzban_user["subscription_url"]
    qr_code_url = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=#{URI.encode(subscription_url)}"

    username = marzban_user["username"] |> Markdown.escape()
    escaped_sub_url = Markdown.escape(subscription_url)

    links_text =
      case marzban_user["links"] do
        links when is_list(links) and links != [] ->
          escaped_links = Enum.map(links, &"`#{Markdown.escape(&1)}`")
          "\n\n*Ключи*:\n" <> Enum.join(escaped_links, "\n\n")

        _ ->
          ""
      end

    caption =
      ~s"""
      *Подключение: `#{username}`*

      Используйте QR-код или ссылку ниже для импорта.

      *Ссылка на подписку*:
      `#{escaped_sub_url}`#{links_text}
      """

    Context.send_photo(chat_id, qr_code_url, caption: caption, parse_mode: "MarkdownV2")
  end
end
