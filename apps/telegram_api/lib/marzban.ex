defmodule TelegramApi.Marzban do
  @moduledoc """
  Client for the Marzban API using standard HTTPS requests.
  """

  require Logger

  defp finch_name, do: Application.get_env(:telegram_api, :finch_name)
  defp base_url, do: Application.get_env(:telegram_api, :marzban)[:base_url]
  defp username, do: Application.get_env(:telegram_api, :marzban)[:username]
  defp password, do: Application.get_env(:telegram_api, :marzban)[:password]

  defp request(request) do
    Finch.request(request, finch_name())
  end

  def get_admin_token do
    url = base_url() <> "/api/admin/token"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    body = URI.encode_query(%{username: username(), password: password()})

    case Finch.build(:post, url, headers, body) |> request() do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)["access_token"]}

      {:ok, response} ->
        Logger.error("Marzban API error on get_admin_token: #{inspect(response)}")
        {:error, :request_failed}

      {:error, reason} ->
        Logger.error("Finch error on get_admin_token: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_user(username) do
    with {:ok, token} <- get_admin_token() do
      url = base_url() <> "/api/user/#{username}"
      headers = [{"Authorization", "Bearer #{token}"}, {"Accept", "application/json"}]

      case Finch.build(:get, url, headers) |> request() do
        {:ok, %{status: 200, body: body}} ->
          {:ok, Jason.decode!(body)}

        {:ok, %{status: 404}} ->
          {:error, :not_found}

        {:ok, response} ->
          Logger.error("Marzban API error on get_user: #{inspect(response)}")
          {:error, :request_failed}

        {:error, reason} ->
          Logger.error("Finch error on get_user: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  def get_users() do
    with {:ok, token} <- get_admin_token() do
      url = base_url() <> "/api/users"
      headers = [{"Authorization", "Bearer #{token}"}, {"Accept", "application/json"}]

      case Finch.build(:get, url, headers) |> request() do
        {:ok, %{status: 200, body: body}} ->
          {:ok, Jason.decode!(body)}

        {:ok, response} ->
          Logger.error("Marzban API error on get_users: #{inspect(response)}")
          {:error, :request_failed}

        {:error, reason} ->
          Logger.error("Finch error on get_users: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  def get_next_username_for(base_username) do
    with {:ok, %{"users" => users}} <- get_users() do
      base_prefix = base_username <> "_"

      existing_numbers =
        users
        |> Enum.map(& &1["username"])
        |> Enum.filter(&String.starts_with?(&1, base_prefix))
        |> Enum.map(fn username ->
          try do
            case String.split(username, base_prefix) do
              ["", number_str] when number_str != "" ->
                {true, String.to_integer(number_str)}

              _ ->
                {false, 0}
            end
          rescue
            _ -> {false, 0}
          end
        end)
        |> Enum.filter(fn {is_valid, _} -> is_valid end)
        |> Enum.map(fn {_, number} -> number end)

      next_number = 
        if Enum.empty?(existing_numbers) do
          0
        else
          Enum.max(existing_numbers) + 1
        end
      next_username = base_prefix <> Integer.to_string(next_number)
      {:ok, next_username}
    else
      error ->
        Logger.error("Could not determine next username for #{base_username}: #{inspect(error)}")
        error
    end
  end

  def create_user(username, note \\ "Создан автоматически Telegram-ботом") do
    with {:ok, token} <- get_admin_token() do
      url = base_url() <> "/api/user"
      headers = [{"Authorization", "Bearer #{token}"}, {"Content-Type", "application/json"}, {"Accept", "application/json"}]

      # Устанавливаем срок действия на 30 дней
      expire_in_30_days =
        DateTime.utc_now()
        |> DateTime.add(30 * 24 * 3600, :second)
        |> DateTime.to_unix()

      body_map = %{
        username: username,
        proxies: %{
          vless: %{}
        },
        inbounds: %{
          vless: ["VLESS TCP REALITY"]
        },
        expire: expire_in_30_days,
        data_limit: 0, # 0 = безлимитный трафик
        data_limit_reset_strategy: "no_reset",
        on_hold_expire_duration: 60,
        note: note
      }

      body = Jason.encode!(body_map)

      case Finch.build(:post, url, headers, body) |> request() do
        {:ok, %{status: 200, body: body}} ->
          {:ok, Jason.decode!(body)}

        {:ok, %{status: 409}} ->
          # Conflict, user already exists
          {:error, :conflict}

        {:ok, response} ->
          Logger.error("Marzban API error on create_user: #{inspect(response)}")
          {:error, :request_failed}

        {:error, reason} ->
          Logger.error("Finch error on create_user: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end
end
