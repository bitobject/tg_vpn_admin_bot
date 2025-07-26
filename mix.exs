defmodule TelegramAdminApi.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: true,
      deps: deps(),
      releases: [
        telegram_admin_api: [
          applications: [
            admin_api: :permanent,
            core: :permanent,
            telegram_api: :permanent
          ]
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.2"},
      {:bandit, ">= 1.7.0"},
      {:telegex, "~> 1.8"}
    ]
  end
end
