defmodule TelegramApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :telegram_api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {TelegramApi.Application, []},
      extra_applications: [:logger, :finch, :jason]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, in_umbrella: true, runtime: false},
      {:telegex, "~>1.8.0"},
      {:finch, "~> 0.18"},
      {:multipart, "~> 0.4"},
      {:bandit, "~> 1.5"},
      {:plug, "~> 1.15"},
      {:remote_ip, "~> 0.3.0"}
    ]
  end
end
