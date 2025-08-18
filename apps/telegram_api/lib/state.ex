defmodule TelegramApi.State do
  use GenServer

  @qr_table_name :qr_message_ids
  @last_message_table_name :last_message_ids

  # --- Client API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # QR Message ID
  def set_qr_message_id(chat_id, qr_message_id) do
    :ets.insert(@qr_table_name, {chat_id, qr_message_id})
  end

  def get_qr_message_id(chat_id) do
    case :ets.lookup(@qr_table_name, chat_id) do
      [{^chat_id, qr_id}] -> {:ok, qr_id}
      [] -> :not_found
    end
  end

  def delete_qr_message_id(chat_id) do
    :ets.delete(@qr_table_name, chat_id)
  end

  # Last Message ID
  def set_last_message_id(chat_id, message_id) do
    :ets.insert(@last_message_table_name, {chat_id, message_id})
  end

  def get_last_message_id(chat_id) do
    case :ets.lookup(@last_message_table_name, chat_id) do
      [{^chat_id, message_id}] -> {:ok, message_id}
      [] -> :not_found
    end
  end

  # --- Server Callbacks ---

  @impl true
  def init(_state) do
    :ets.new(@qr_table_name, [:set, :public, :named_table, read_concurrency: true])
    :ets.new(@last_message_table_name, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end
end
