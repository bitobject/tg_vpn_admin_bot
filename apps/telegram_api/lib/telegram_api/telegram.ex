defmodule TelegramApi.Telegram do
  @moduledoc """
  Provides helper functions to interact with the Telegram API via Telegex.
  """

  @doc """
  Extracts chat_id from an update.
  """
  def get_chat_id(%Telegex.Type.Update{message: %Telegex.Type.Message{chat: %{id: chat_id}}}),
    do: {:ok, chat_id}

  def get_chat_id(%Telegex.Type.Update{callback_query: %Telegex.Type.CallbackQuery{message: %Telegex.Type.Message{chat: %{id: chat_id}}}}),
    do: {:ok, chat_id}
  def get_chat_id(%{callback_query: %{message: %{chat: %{id: id}}}}), do: {:ok, id}
  def get_chat_id(_update), do: {:error, :no_chat_id}

  @doc """
  Extracts the 'from' field from an update.
  """
  def get_from(%{message: %{from: from}}), do: {:ok, from}
  def get_from(%{callback_query: %{from: from}}), do: {:ok, from}
  def get_from(_update), do: {:error, :no_from_field}

  @doc """
  Extracts username from the 'from' field.
  """
  def get_username(%{username: username}), do: {:ok, username}
  def get_username(_), do: {:error, :no_username}

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

  @doc """
  Edits a text message.
  """
  def edit_message_text(chat_id, message_id, text, opts \\ []) do
    all_opts =
      [chat_id: chat_id, message_id: message_id]
      |> Keyword.merge(opts)

    Telegex.edit_message_text(text, all_opts)
  end
end
