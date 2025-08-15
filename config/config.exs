# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

# Configure Marzban API
# It's recommended to move these to environment-specific configs (e.g., prod.exs)
# and use System.get_env/1 for sensitive data in production.
config :telegram_api, finch_name: TelegramApi.Finch
config :telegram_api, :marzban,
  base_url: "https://ancanot.xyz",
  username: "pro_admin",
  password: "lidersit"

# Configure Telegex handlers
config :telegex,
  chains: [
    TelegramApi.RespStartChain,
    TelegramApi.RespCreateConnectionChain, # Handles the very first connection
    TelegramApi.RespAddConnectionChain # Handles subsequent connections
  ]

# Configure the main application
config :admin_api,
  namespace: AdminApi,
  generators: [timestamp_type: :utc_datetime]

config :core, ecto_repos: [Core.Repo]
# Configure Phoenix to not start its own server. This will be handled by the Bandit adapter.
config :admin_api, AdminApiWeb.Endpoint, server: false

# esbuild configuration removed for API-only application

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
