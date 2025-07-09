defmodule TelegramApi.WebhookPlug do
  import Plug.Conn
  require Logger

  alias TelegramContext

  @behaviour Plug

  def init(opts), do: opts

  def call(%Plug.Conn{method: "POST"} = conn, _opts) do
    {:ok, body, conn} = read_body(conn)

    case Jason.decode(body) do
      {:ok, update} ->
        log_update(update)
        process_update(update)

      {:error, _} ->
        Logger.error("Invalid JSON in webhook")
    end

    send_resp(conn, 200, "ok")
  end

  def call(conn, _opts), do: send_resp(conn, 405, "Method Not Allowed")

  defp log_update(update) do
    user_id = get_user_id(update)
    TelegramContext.log_update(%{user_id: user_id, update: update})
  end

  defp process_update(%{"message" => %{"text" => "/start" = _text, "from" => from}} = _update) do
    attrs = telegram_user_attrs(from)
    TelegramContext.create_or_update_user(attrs)
    send_greeting(from)
  end

  defp process_update(_), do: :ok

  defp get_user_id(%{"message" => %{"from" => %{"id" => id}}}), do: id
  defp get_user_id(_), do: nil

  defp telegram_user_attrs(from) do
    %{
      id: from["id"],
      is_bot: from["is_bot"],
      first_name: from["first_name"],
      last_name: from["last_name"],
      username: from["username"],
      language_code: from["language_code"],
      is_premium: from["is_premium"],
      added_to_attachment_menu: from["added_to_attachment_menu"],
      can_join_groups: from["can_join_groups"],
      can_read_all_group_messages: from["can_read_all_group_messages"],
      supports_inline_queries: from["supports_inline_queries"]
    }
  end

  defp send_greeting(from) do
    chat_id = from["id"]
    lang = from["language_code"] || "en"
    text = greeting_text(lang)

    send_fun =
      Application.get_env(:telegram_api, :telegram_client_send_message) ||
        (&TelegramApi.TelegramClient.send_message/2)

    send_fun.(chat_id, text)
  end

  defp greeting_text("ru"), do: "Привет! Добро пожаловать!"
  defp greeting_text(_), do: "Hello! Welcome!"
end
