# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

# Configure the main application
config :admin_api,
  namespace: AdminApi,
  ecto_repos: [Core.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure Phoenix to not start its own server. This will be handled by the Bandit adapter.
config :admin_api, AdminApiWeb.Endpoint,
  server: false

# esbuild configuration removed for API-only application

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
