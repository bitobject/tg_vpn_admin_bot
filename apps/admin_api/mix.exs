defmodule AdminApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :admin_api,
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
      extra_applications: [:logger, :runtime_tools],
      mod: {AdminApi.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Web framework
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:plug_cowboy, "~> 2.6"},

      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # Authentication & Security
      {:bcrypt_elixir, "~> 3.0"},
      {:jason, "~> 1.4"},
      {:guardian, "~> 2.3"},

      # API Documentation
      {:phoenix_swagger, "~> 0.6"},
      {:ex_json_schema, "~> 0.10"},

      # Rate limiting
      {:hammer, "~> 6.1"},

      # Validation
      {:ecto_psql_extras, "~> 0.7"},

      # Development & Testing
      {:swoosh, "~> 1.11"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:junit_formatter, "~> 3.3", only: :test},

      # Sibling apps
      {:core, in_umbrella: true}
    ]
  end
end
