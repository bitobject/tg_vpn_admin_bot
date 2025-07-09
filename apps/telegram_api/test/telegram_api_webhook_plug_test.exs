defmodule TelegramApi.WebhookPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Core.{Repo, TelegramUser, TelegramUpdateLog}
  import Ecto.Query

  @opts TelegramApi.WebhookPlug.init([])

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Core.Repo)
    :ok
  end

  test "creates and updates user, logs update, sends greeting on /start" do
    # Мокаем TelegramClient
    me = self()
    :me = me
    old_send = Application.get_env(:telegram_api, :telegram_client_send_message)

    Application.put_env(:telegram_api, :telegram_client_send_message, fn chat_id, text ->
      send(me, {:sent_greeting, chat_id, text})
      :ok
    end)

    update = %{
      "update_id" => 1,
      "message" => %{
        "message_id" => 1,
        "from" => %{
          "id" => 123,
          "is_bot" => false,
          "first_name" => "Ivan",
          "last_name" => "Ivanov",
          "username" => "ivanivanov",
          "language_code" => "ru"
        },
        "chat" => %{"id" => 123},
        "date" => 1_680_000_000,
        "text" => "/start"
      }
    }

    conn =
      conn(:post, "/webhook", Jason.encode!(update))
      |> put_req_header("content-type", "application/json")

    resp = TelegramApi.WebhookPlug.call(conn, @opts)
    assert resp.status == 200
    assert resp.resp_body == "ok"

    # Проверяем, что пользователь создан
    user = Repo.get(TelegramUser, 123)
    assert user
    assert user.first_name == "Ivan"
    assert user.language_code == "ru"

    # Проверяем, что апдейт залогирован
    log = Repo.one(from(l in TelegramUpdateLog, where: l.user_id == 123))
    assert log
    assert log.update["message"]["text"] == "/start"

    # Проверяем, что отправлено приветствие
    assert_receive {:sent_greeting, 123, "Привет! Добро пожаловать!"}

    # Обновляем пользователя
    update2 = put_in(update["message"]["from"]["first_name"], "Petr")

    conn2 =
      conn(:post, "/webhook", Jason.encode!(update2))
      |> put_req_header("content-type", "application/json")

    TelegramApi.WebhookPlug.call(conn2, @opts)
    user2 = Repo.get(TelegramUser, 123)
    assert user2.first_name == "Petr"

    # Восстанавливаем старый env
    if old_send, do: Application.put_env(:telegram_api, :telegram_client_send_message, old_send)
  end
end
