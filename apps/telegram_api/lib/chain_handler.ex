defmodule TelegramApi.ChainHandler do
  @moduledoc false

  use Telegex.Chain.Handler

  pipeline([
    # Command handlers
    TelegramApi.Chain.RespStartChain,
    TelegramApi.Chain.RespTariffsChain,

    # Callback query handlers
    TelegramApi.Chain.RespPayTariffChain,
    TelegramApi.Chain.RespCreateConnectionChain,
    TelegramApi.Chain.ShowConnectionLinkChain,
    TelegramApi.Chain.PersonalAccountChain,
    TelegramApi.Chain.CallHelloChain,

    # Fallback for any other text
    TelegramApi.Chain.FallbackChain
  ])
end
