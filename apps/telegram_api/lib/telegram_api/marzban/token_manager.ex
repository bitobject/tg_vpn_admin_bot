defmodule TelegramApi.Marzban.TokenManager do
  @moduledoc """
  Manages the Marzban API token, caching it to avoid re-fetching on every request.
  """
  use GenServer

  require Logger

  @cache_key :marzban_api_token
  @ttl :timer.minutes(55) # Marzban tokens typically last for 1 hour

  # Public API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_token do
    case :persistent_term.get(@cache_key, nil) do
      nil ->
        GenServer.call(__MODULE__, :fetch_token)

      token ->
        {:ok, token}
    end
  end

  # GenServer Callbacks
  @impl true
  def init(:ok) do
    schedule_fetch()
    {:ok, %{}}
  end

  @impl true
  def handle_call(:fetch_token, _from, state) do
    case do_fetch_token() do
      {:ok, token} ->
        :persistent_term.put(@cache_key, token)
        schedule_fetch()
        {:reply, {:ok, token}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(:fetch_token, state) do
    case do_fetch_token() do
      {:ok, token} ->
        :persistent_term.put(@cache_key, token)
        schedule_fetch()

      {:error, reason} ->
        Logger.error("Failed to refresh Marzban token: #{inspect(reason)}")
        # Retry after a short delay
        :timer.send_after(:timer.seconds(30), self(), :fetch_token)
    end

    {:noreply, state}
  end

  defp do_fetch_token do
    url = base_url() <> "/api/admin/token"
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    body = URI.encode_query(%{username: username(), password: password()})
    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, finch_name()) do
      {:ok, %{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"access_token" => token}} -> {:ok, token}
          _ -> {:error, :token_decode_failed}
        end

      other ->
        Logger.error("Marzban token request failed: #{inspect(other)}")
        {:error, :token_request_failed}
    end
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch_token, @ttl)
  end

  defp finch_name, do: Application.get_env(:telegram_api, :finch_name)
  defp base_url, do: Application.get_env(:telegram_api, :marzban)[:base_url]
  defp username, do: Application.get_env(:telegram_api, :marzban)[:username]
  defp password, do: Application.get_env(:telegram_api, :marzban)[:password]
end
