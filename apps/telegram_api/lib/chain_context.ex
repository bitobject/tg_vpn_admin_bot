defmodule TelegramApi.ChainContext do
  @moduledoc false

  use Telegex.Chain.Context

  defcontext([
    {:chat_id, integer() | nil},
    {:user_id, integer() | nil},
    {:chat_title, String.t() | nil}
  ])
end
