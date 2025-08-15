defmodule TelegramApi.ChainHandler do
  @moduledoc false

  use Telegex.Chain.Handler

  pipeline([
    # Command handlers
    TelegramApi.Chain.RespStartChain,

    # Callback query handlers
    TelegramApi.Chain.RespCreateConnectionChain,
    TelegramApi.Chain.RespAddConnectionChain,
    TelegramApi.Chain.PersonalAccountChain,
    TelegramApi.Chain.CallHelloChain,

    # Fallback for any other text
    TelegramApi.Chain.FallbackChain
  ])
end
