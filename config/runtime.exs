import Config

# Configure your database
config :core, Core.Repo,
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  hostname: System.get_env("DB_HOST", "localhost"),
  database: System.get_env("DB_NAME", "telegram_admin_api_#{config_env()}"),
  stacktrace: config_env() == :dev,
  show_sensitive_data_on_connection_error: config_env() == :dev,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

# Configure the main application
config :admin_api,
  namespace: AdminApi,
  ecto_repos: [Core.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure Guardian for JWT
config :admin_api, AdminApi.Guardian,
  issuer: "telegram_admin_api",
  secret_key:
    System.get_env("GUARDIAN_SECRET_KEY") || "your-secret-key-here-change-in-production",
  ttl: {1, :day},
  refresh_ttl: {30, :days}

# Configure Phoenix
config :admin_api, AdminApiWeb.Endpoint,
  url: [host: System.get_env("HOST", "localhost")],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [json: AdminApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AdminApi.PubSub,
  live_view: [signing_salt: "your-signing-salt"],
  secret_key_base:
    System.get_env("SECRET_KEY_BASE") || "your-secret-key-base-here-change-in-production"

# Configure rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

# Configure logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure telemetry poller
config :telemetry_poller,
  measurements: [
    # A module, function and arguments to be invoked periodically.
    # {Core, :count_users, []},
    {TelemetryPoller, :measure, []}
  ],
  period: 10_000
