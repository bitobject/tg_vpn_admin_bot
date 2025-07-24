defmodule TelegramApi.ChainHandler do
  @moduledoc false

  use Telegex.Chain.Handler

  pipeline([
    TelegramApi.RespStartChain,
    TelegramApi.EchoTextChain,
    TelegramApi.CallHelloChain
  ])
end
