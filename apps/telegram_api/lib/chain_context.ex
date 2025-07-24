defmodule TelegramApi.ChainContext do
  @moduledoc false

  use Telegex.Chain.Context

  defstruct([
    :bot,
    :chat_id,
    :user_id,
    :chat_title,
    :payload
  ])

  defcontext([
    {:bot, Telegex.Type.User.t()},
    {:chat_id, integer() | nil},
    {:user_id, integer() | nil},
    {:chat_title, String.t() | nil},
    {:payload, map() | nil}
  ])
end
