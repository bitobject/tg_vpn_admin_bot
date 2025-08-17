defmodule TelegramApi.Context do
  @moduledoc """
  Context module for managing data and Telegram interactions.
  """

  alias Core.Repo
  alias TelegramUser

  #
  # Database functions
  #

  @doc """
  Gets a single user by username.
  """
  def get_by_username(username) do
    Repo.get(TelegramUser, username)
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs) do
    %TelegramUser{}
    |> TelegramUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%TelegramUser{} = user, attrs) do
    user
    |> TelegramUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Adds a new Marzban username to the user's list of connections.
  """
  def add_marzban_user(%TelegramUser{} = user, marzban_username) do
    new_marzban_users = [marzban_username | user.marzban_users]
    update_user(user, %{marzban_users: new_marzban_users})
  end

  #
  # Telegram API helpers
  #

  @doc """
  Extracts chat_id from an update.
  """
  def get_chat_id(update),
    do: IO.inspect(update, label: "CONTEXT: get_chat_id received") |> do_get_chat_id()

  defp do_get_chat_id(%{message: %{chat: %{id: id}}}), do: {:ok, id}
  defp do_get_chat_id(%{callback_query: %{message: %{chat: %{id: id}}}}), do: {:ok, id}
  defp do_get_chat_id(_update), do: {:error, :no_chat_id}

  @doc """
  Extracts the 'from' field from an update.
  """
  def get_from(update),
    do: IO.inspect(update, label: "CONTEXT: get_from received") |> do_get_from()

  defp do_get_from(%{message: %{from: from}}), do: {:ok, from}
  defp do_get_from(%{callback_query: %{from: from}}), do: {:ok, from}
  defp do_get_from(_update), do: {:error, :no_from_field}

  @doc """
  Extracts username from the 'from' field.
  """
  def get_username(from),
    do: IO.inspect(from, label: "CONTEXT: get_username received") |> do_get_username()

  defp do_get_username(%{username: username}), do: {:ok, username}
  defp do_get_username(_), do: {:error, :no_username}

  @doc """
  Sends a text message.
  """
  def send_message(chat_id, text, opts \\ []) do
    Telegex.send_message(chat_id, text, opts)
  end

  @doc """
  Sends a photo.
  """
  def send_photo(chat_id, photo_url, opts \\ []) do
    Telegex.send_photo(chat_id, photo_url, opts)
  end

  @doc """
  Answers a callback query.
  """
  def answer_callback_query(callback_query_id, opts \\ []) do
    Telegex.answer_callback_query(callback_query_id, opts)
  end
end
