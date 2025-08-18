defmodule TelegramApi.Chain.ConnectionHelper do
  require Logger
  alias TelegramApi.Telegram
  alias TelegramApi.Marzban
  alias TelegramApi.State

  @type marzban_user :: map()
  @type tariff :: map()

  @spec process_user_connections(integer(), any(), integer()) :: :ok
  def process_user_connections(chat_id, user, loading_message_id) do
    marzban_usernames = user.marzban_users

    # First, delete the "Loading..." message
    Telegram.delete_message(chat_id, loading_message_id)

    if Enum.empty?(marzban_usernames) do
      send_add_connection_button(
        chat_id,
        "У вас еще нет подключений. Вы можете создать новое в меню тарифов."
      )
    else
      # Fetch all user data concurrently
      tasks =
        Enum.map(marzban_usernames, fn username ->
          Task.async(fn -> Marzban.get_user(username) end)
        end)

      results = Task.await_many(tasks, 30000)

      # Filter for successfully fetched users
      users =
        Enum.filter(results, fn
          {:ok, _} -> true
          _ -> false
        end)
        |> Enum.map(fn {:ok, u} -> u end)

      if Enum.empty?(users) do
        Telegram.send_message(
          chat_id,
          "Не удалось загрузить информацию о ваших подключениях. Попробуйте позже."
        )
      else
        # Send a separate message for each connection
        for marzban_user <- users do
          text = generate_connection_text(marzban_user)

          keyboard = %{
            inline_keyboard: [
              [
                %{
                  text: "🔗 Получить ссылки (#{marzban_user["username"]})",
                  callback_data: "show_connection_link:#{marzban_user["username"]}"
                }
              ]
            ]
          }

          Telegram.send_message(chat_id, text, parse_mode: "Markdown", reply_markup: keyboard)
        end
      end

      # Finally, send the 'Add Connection' button and store its ID
      send_add_connection_button(chat_id, "Вы можете добавить еще одно подключение.")
    end

    :ok
  end

  defp send_add_connection_button(chat_id, text) do
    case Telegram.send_message(chat_id, text,
           reply_markup: %{
             inline_keyboard: [
               [%{text: "➕ Добавить подключение", callback_data: "add_connection:v1"}]
             ]
           }
         ) do
      {:ok, %Telegex.Type.Message{message_id: message_id}} ->
        State.set_last_message_id(chat_id, message_id)

      {:error, reason} ->
        Logger.error(
          "Failed to send 'Add Connection' button and store message_id: #{inspect(reason)}"
        )
    end
  end

  @spec extend_marzban_user(marzban_user(), tariff()) :: {:ok, marzban_user()} | {:error, any()}
  @spec create_marzban_user(tariff(), String.t()) :: {:ok, marzban_user()} | {:error, any()}
  def create_marzban_user(tariff, username_prefix) do
    with {:ok, new_username} <- Marzban.get_next_username_for(username_prefix) do
      expire = tariff_to_expire(tariff)
      data_limit = Map.get(tariff, :data_limit_bytes, 0)
      data_limit = if is_number(data_limit), do: trunc(data_limit), else: 0

      body = %{
        "username" => new_username,
        "proxies" => %{
          "vless" => %{}
        },
        "inbounds" => %{
          "vless" => ["VLESS TCP REALITY"]
        },
        "expire" => expire || 0,
        "data_limit" => data_limit,
        "data_limit_reset_strategy" => "no_reset",
        "on_hold_expire_duration" => 60,
        "note" => "Created by TG Bot"
      }

      Marzban.create_user(body)
    end
  end

  @spec extend_marzban_user(marzban_user(), tariff()) :: {:ok, marzban_user()} | {:error, any()}
  def extend_marzban_user(marzban_user, tariff) do
    current_expire = marzban_user["expire"] || 0

    start_time =
      if current_expire > DateTime.to_unix(DateTime.utc_now()),
        do: current_expire,
        else: DateTime.to_unix(DateTime.utc_now())

    new_expire = start_time + round(tariff.duration_days * 24 * 3600)

    body = %{
      "expire" => new_expire,
      "data_limit" => 0
    }

    Marzban.modify_user(marzban_user["username"], body)
  end

  # Private helpers

  defp format_traffic(data_limit, used_traffic) do
    used_gb = (used_traffic || 0) / (1024 * 1024 * 1024)
    used_gb_str = :erlang.float_to_binary(used_gb, decimals: 2)

    limit_str =
      case data_limit do
        0 ->
          "Безлимитно"

        nil ->
          "Безлимитно"

        limit when is_integer(limit) and limit > 0 ->
          limit_gb = limit / (1024 * 1024 * 1024)
          limit_gb_str = :erlang.float_to_binary(limit_gb, decimals: 2)
          "#{limit_gb_str} GB"
      end

    "#{used_gb_str} GB / #{limit_str}"
  end

  def format_expire_date(0), do: "Никогда"

  def format_expire_date(unix_timestamp) when is_integer(unix_timestamp) do
    case DateTime.from_unix(unix_timestamp) do
      {:ok, datetime} -> Calendar.strftime(datetime, "%d.%m.%Y")
      _ -> "Неверная дата"
    end
  end

  defp format_status("active"), do: "Активен ✅"
  defp format_status("disabled"), do: "Отключен ❌"
  defp format_status("expired"), do: "Истек ⏳"
  defp format_status("limited"), do: "Ограничен 😥"
  defp format_status(_), do: "Неизвестен"

  @spec generate_connection_text(marzban_user()) :: String.t()
  def generate_connection_text(marzban_user) do
    # IO.inspect(marzban_user, label: "[ConnectionHelper] Generating text for marzban_user")
    username = marzban_user["username"]
    status = marzban_user["status"] |> format_status()
    traffic = format_traffic(marzban_user["data_limit"], marzban_user["used_traffic"])
    expire_date = format_expire_date(marzban_user["expire"])

    """
    *Подключение:* `#{username}`
    *Статус:* #{status}
    *Трафик:* #{traffic}
    *Действует до:* #{expire_date}
    """
  end

  @spec send_connection_card(integer(), String.t(), String.t()) :: :ok
  def send_connection_card(chat_id, username, text) do
    keyboard = %{
      inline_keyboard: [
        [
          %{text: "Оплатить/Продлить", callback_data: "view_tariffs:#{username}"},
          %{text: "Ссылка для подключения", callback_data: "show_connection_link:#{username}"}
        ]
      ]
    }

    Telegram.send_message(chat_id, text, parse_mode: "Markdown", reply_markup: keyboard)
    :ok
  end

  def tariff_to_expire(tariff) do
    if tariff.duration_days > 0 do
      DateTime.utc_now()
      |> DateTime.add(round(tariff.duration_days * 24 * 3600), :second)
      |> DateTime.to_unix()
    else
      0
    end
  end
end
