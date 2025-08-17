defmodule TelegramApi.Chain.ConnectionHelper do
  require Logger
  alias TelegramApi.Context, as: Context
  alias TelegramApi.Marzban

  @type marzban_user :: map()
  @type tariff :: map()

  @spec process_user_connections(integer(), any()) :: :ok | :failed_to_fetch
  def process_user_connections(chat_id, user) do
    marzban_usernames = user.marzban_users

    if Enum.empty?(marzban_usernames) do
      Context.send_message(
        chat_id,
        "У вас еще нет активных подключений. Вы можете создать новое в меню тарифов."
      )

      :ok
    else
      Context.send_message(chat_id, "Загружаю информацию о ваших подключениях...")

      tasks =
        Enum.map(marzban_usernames, fn username ->
          Task.async(fn -> {username, Marzban.get_user(username)} end)
        end)

      results = Task.await_many(tasks, 30000)

      {ok_results, error_results} =
        Enum.split_with(results, fn
          {_username, {:ok, _user}} -> true
          _ -> false
        end)

      unless Enum.empty?(error_results) do
        Logger.error("Failed to fetch some users from Marzban: #{inspect(error_results)}")
      end

      if Enum.empty?(ok_results) and not Enum.empty?(marzban_usernames) do
        Context.send_message(
          chat_id,
          "Не найдено активных подключений, связанных с вашим аккаунтом."
        )
      else
        users = Enum.map(ok_results, fn {_, {:ok, user}} -> user end)

        Enum.each(users, fn user ->
          details = generate_connection_details(user)
          send_connection_details(chat_id, details)
        end)
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
    current_data_limit = marzban_user["data_limit"] || 0
    new_data_limit = tariff.data_limit_bytes || 0

    start_time =
      if current_expire > DateTime.to_unix(DateTime.utc_now()),
        do: current_expire,
        else: DateTime.to_unix(DateTime.utc_now())

    new_expire = start_time + round(tariff.duration_days * 24 * 3600)

    updated_data_limit =
      if current_data_limit == 0 || new_data_limit == 0 do
        0
      else
        current_data_limit + new_data_limit
      end

    body = %{
      "expire" => new_expire,
      "data_limit" => updated_data_limit
    }

    Marzban.modify_user(marzban_user["username"], body)
  end

  @spec generate_connection_details(marzban_user()) :: map()
  def generate_connection_details(marzban_user) do
    subscription_url = marzban_user["subscription_url"]

    qr_code_url =
      "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=#{URI.encode(subscription_url)}"

    caption = """
    *Подключение*: `#{marzban_user["username"]}`

    *Статус*: #{format_status(marzban_user["status"])}
    *Трафик*: #{format_traffic(marzban_user["used_traffic"])} / #{format_traffic(marzban_user["data_limit"])}
    *Действует до*: #{format_expire_date(marzban_user["expire"])}

    Для импорта отсканируйте QR-код или скопируйте ссылку ниже.
    """

    %{
      qr_code_url: qr_code_url,
      caption: caption,
      subscription_url: subscription_url,
      username: marzban_user["username"]
    }
  end

  @spec send_connection_details(integer(), map()) :: :ok
  def send_connection_details(chat_id, details) do
    keyboard = %{
      inline_keyboard: [
        [
          %{
            text: "Оплатить/Продлить",
            callback_data: "view_tariffs:#{details.username}"
          }
        ]
      ]
    }

    Context.send_photo(chat_id, details.qr_code_url,
      caption: details.caption,
      parse_mode: "Markdown",
      reply_markup: keyboard
    )

    Context.send_message(chat_id, "`#{details.subscription_url}`", parse_mode: "Markdown")
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

  def format_traffic(0), do: "Безлимитный"
  def format_traffic(nil), do: "Безлимитный"

  def format_traffic(bytes) when is_integer(bytes) do
    gb = bytes / (1024 * 1024 * 1024)
    "#{:erlang.float_to_binary(gb, decimals: 2)} GB"
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
end
