defmodule TelegramApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Mix.env() == :test do
        []
      else
        [
          {Plug.Cowboy,
           scheme: :http,
           plug: TelegramApi.WebhookPlug,
           options: [port: 4002, dispatch: dispatch()]}
        ]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TelegramApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/webhook", TelegramApi.WebhookPlug, []},
         {:_, Plug.Cowboy.Handler, {TelegramApi.WebhookPlug, []}}
       ]}
    ]
  end
end
