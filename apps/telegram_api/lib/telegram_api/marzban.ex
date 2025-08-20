defmodule TelegramApi.Marzban do
  @moduledoc """
  Public API for interacting with the Marzban service.

  This module is a facade that delegates calls to the `TelegramApi.Marzban.Client`.
  """

  alias TelegramApi.Marzban.Client

  @doc """
  Delegates to `TelegramApi.Marzban.Client.get_user/1`.
  """
  defdelegate get_user(username), to: Client

  @doc """
  Delegates to `TelegramApi.Marzban.Client.get_users/1`.
  """
  defdelegate get_users(params \\ %{}), to: Client

  @doc """
  Delegates to `TelegramApi.Marzban.Client.create_user/1`.
  """
  defdelegate create_user(body), to: Client

  @doc """
  Delegates to `TelegramApi.Marzban.Client.modify_user/2`.
  """
  defdelegate modify_user(username, body), to: Client

  @doc """
  Delegates to `TelegramApi.Marzban.Client.remove_user/1`.
  """
  defdelegate remove_user(username), to: Client

  @doc """
  Delegates to `TelegramApi.Marzban.Client.get_next_username_for/1`.
  """
  defdelegate get_next_username_for(base_username), to: Client
end
