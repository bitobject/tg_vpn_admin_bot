defmodule TelegramApi.Chain.ConnectionHelper do
  require Logger
  alias TelegramApi.Marzban

  @type marzban_user :: map()
  @type tariff :: map()

  @spec build_personal_account_content(any()) :: {String.t(), map()}
  def build_personal_account_content(user) do
    marzban_usernames = user.marzban_users

    tasks =
      Enum.map(marzban_usernames, fn username ->
        Task.async(fn -> Marzban.get_user(username) end)
      end)

    results = Task.await_many(tasks, 30000)

    connection_rows =
      results
      |> Enum.filter(fn
        {:ok, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {:ok, u} -> u end)
      |> Enum.flat_map(&build_connection_keyboard_rows(&1))

    add_connection_button = [
      %{text: "➕ Добавить подключение", callback_data: "add_connection:new"}
    ]

    keyboard_rows = connection_rows ++ [add_connection_button]

    text =
      if Enum.empty?(connection_rows),
        do: "У вас нет активных подключений.",
        else: "Личный кабинет"

    keyboard = %{inline_keyboard: keyboard_rows}
    {text, keyboard}
  end

  def build_connection_keyboard_rows(marzban_user) do
    username = marzban_user["username"]
    status_emoji = format_status_to_emoji(marzban_user["status"])

    [
      [%{text: "#{status_emoji} #{username}", callback_data: "show_connection_link:#{username}"}]
    ]
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

  def format_status("active"), do: "Активен ✅"
  def format_status("disabled"), do: "Отключен ❌"
  def format_status("expired"), do: "Истек ⏳"
  def format_status("limited"), do: "Ограничен 😥"
  def format_status(_), do: "Неизвестен"

  defp format_status_to_emoji("active"), do: "✅"
  defp format_status_to_emoji("disabled"), do: "❌"
  defp format_status_to_emoji("expired"), do: "⏳"
  defp format_status_to_emoji("limited"), do: "😥"
  defp format_status_to_emoji(_), do: ""

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
