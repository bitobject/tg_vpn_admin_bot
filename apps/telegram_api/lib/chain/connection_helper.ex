defmodule TelegramApi.Chain.ConnectionHelper do
  require Logger
  alias TelegramApi.Telegram
  alias TelegramApi.Marzban

  @type marzban_user :: map()
  @type tariff :: map()

  @spec process_user_connections(integer(), any(), integer()) :: :ok | :failed_to_fetch
  def process_user_connections(chat_id, user, message_id) do
    IO.inspect({chat_id, user, message_id}, label: "[ConnectionHelper] Entered process_user_connections")
    marzban_usernames = user.marzban_users
    IO.inspect(marzban_usernames, label: "[ConnectionHelper] Usernames to process")

    if Enum.empty?(marzban_usernames) do
      Telegram.edit_message_text(
        chat_id,
        message_id,
        "У вас еще нет активных подключений. Вы можете создать новое в меню тарифов."
      )

      :ok
    else
      tasks =
        Enum.map(marzban_usernames, fn username ->
          Task.async(fn -> {username, Marzban.get_user(username)} end)
        end)

      results = Task.await_many(tasks, 30000)
      IO.inspect(results, label: "[ConnectionHelper] Marzban API results")

      {ok_results, error_results} =
        Enum.split_with(results, fn
          {_username, {:ok, _user}} -> true
          _ -> false
        end)

      unless Enum.empty?(error_results) do
        Logger.error("Failed to fetch some users from Marzban: #{inspect(error_results)}")
      end

      if Enum.empty?(ok_results) and not Enum.empty?(marzban_usernames) do
        Telegram.edit_message_text(
          chat_id,
          message_id,
          "Не удалось загрузить информацию о ваших подключениях. Попробуйте позже."
        )
      else
        users = Enum.map(ok_results, fn {_username, {:ok, user}} -> user end)
        IO.inspect(users, label: "[ConnectionHelper] Parsed Marzban users")

        # Consolidate all connections into one message
        full_text =
          users
          |> Enum.map(&generate_connection_text(&1))
          |> Enum.join("\n\n#{String.duplicate("—", 20)}\n\n")
        IO.inspect(full_text, label: "[ConnectionHelper] Final text to be sent")

        keyboard = 
          (Enum.map(users, fn user ->
            [%{text: "🔗 Получить ссылки (#{user["username"]})", callback_data: "show_connection_link:#{user["username"]}"}]
          end) ++ [[%{text: "➕ Добавить подключение", callback_data: "add_connection:v1"}]])

        IO.inspect({chat_id, message_id, full_text, keyboard}, label: "[ConnectionHelper] Arguments for edit_message_text")
        result = Telegram.edit_message_text(chat_id, message_id, full_text, 
          parse_mode: "Markdown",
          reply_markup: %{inline_keyboard: keyboard})
        IO.inspect(result, label: "[ConnectionHelper] Result of edit_message_text")
      end

      :ok
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
        0 -> "Безлимитно"
        nil -> "Безлимитно"
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
