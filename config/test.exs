import Config

config :core, Core.Repo,
  database: "telegram_admin_api_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :admin_api, AdminApiWeb.Endpoint, server: false

# In test we don't send emails.
config :admin_api, :sql_sandbox, true

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
