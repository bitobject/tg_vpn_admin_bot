defmodule TelegramApi.Marzban.Client do
  @moduledoc """
  Client for the Marzban API.
  """

  require Logger

  @type request_method :: :get | :post | :put | :delete
  @type request_path :: String.t()
  @type request_body :: map() | nil
  @type query_params :: map() | nil
  @type response :: {:ok, map()} | {:error, any()}

  @spec get_user(String.t()) :: response()
  def get_user(username) do
    request(:get, "/api/user/#{username}")
  end

  @spec get_users(query_params()) :: response()
  def get_users(params \\ %{}) do
    request(:get, "/api/users", nil, params)
  end

  @spec create_user(map()) :: response()
  def create_user(body) do
    request(:post, "/api/user", body)
  end

  @spec modify_user(String.t(), map()) :: response()
  def modify_user(username, body) do
    request(:put, "/api/user/#{username}", body)
  end

  @spec remove_user(String.t()) :: response()
  def remove_user(username) do
    request(:delete, "/api/user/#{username}")
  end

  @spec get_next_username_for(String.t()) :: {:ok, String.t()} | {:error, any()}
  def get_next_username_for(base_username) do
    with {:ok, %{"users" => all_users}} <- get_users() do
      base_prefix = base_username <> "_"

      last_number =
        all_users
        |> Enum.map(& &1["username"])
        |> Enum.filter(&String.starts_with?(&1, base_prefix))
        |> Enum.map(fn username ->
          case String.split(username, base_prefix) do
            ["", number_str] ->
              case Integer.parse(number_str) do
                {num, ""} -> num
                _ -> 0
              end

            _ ->
              0
          end
        end)
        |> Enum.max(fn -> 0 end)

      next_username = base_prefix <> Integer.to_string(last_number + 1)
      {:ok, next_username}
    else
      error ->
        Logger.error("Could not determine next username for #{base_username}: #{inspect(error)}")
        error
    end
  end

  # Private functions

  defp finch_name, do: Application.get_env(:telegram_api, :finch_name)
  defp base_url, do: Application.get_env(:telegram_api, :marzban)[:base_url]

  defp request(method, path, body \\ nil, params \\ %{}) do
    with {:ok, token} <- TelegramApi.Marzban.TokenManager.get_token() do
      url = build_url(path, params)
      json_body = if body, do: Jason.encode!(body), else: nil
      headers = build_headers(token, with_content_type: not is_nil(json_body))

      finch_request = Finch.build(method, url, headers, json_body)

      case Finch.request(finch_request, finch_name()) do
        {:ok, %{status: 200, body: _}} when method == :delete ->
          :ok

        {:ok, %{status: status, body: resp_body}} when status in [200, 201] ->
          {:ok, Jason.decode!(resp_body)}

        {:ok, %{status: 404}} ->
          {:error, :not_found}

        {:ok, %{status: 409}} ->
          {:error, :conflict}

        {:ok, response} ->
          Logger.error("Marzban API error: #{inspect(response)}")
          {:error, :request_failed}

        {:error, reason} ->
          Logger.error("Finch error: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp build_url(path, params) do
    base = base_url() <> path

    if params && !Enum.empty?(params) do
      query_string = URI.encode_query(params)
      base <> "?" <> query_string
    else
      base
    end
  end

  defp build_headers(token, with_content_type: with_content_type) do
    base_headers = [
      {"Authorization", "Bearer #{token}"},
      {"Accept", "application/json"}
    ]

    if with_content_type do
      [{"Content-Type", "application/json"} | base_headers]
    else
      base_headers
    end
  end
end
