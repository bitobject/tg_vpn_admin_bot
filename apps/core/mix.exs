defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
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
      mod: {Core.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # Authentication & Security
      {:bcrypt_elixir, "~> 3.0"},
      {:guardian, "~> 2.3"},

      # Validation
      {:ecto_psql_extras, "~> 0.7"},

      # Utilities
      {:jason, "~> 1.4"},
      {:timex, "~> 3.7"},

      # Development & Testing
      {:ex_machina, "~> 2.7", only: :test}
    ]
  end
end
