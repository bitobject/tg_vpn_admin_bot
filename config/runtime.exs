import Config

# --------------------------------------------------------------------------
# Environment Variable Loading
# --------------------------------------------------------------------------
# All environment variables are loaded and parsed here to ensure they exist
# at startup and to keep the configuration sections below clean.
#
db_username = System.fetch_env!("DB_USERNAME")
db_password = System.fetch_env!("DB_PASSWORD")
db_host = System.fetch_env!("DB_HOST")
db_name = System.fetch_env!("DB_NAME")
pool_size = System.fetch_env!("POOL_SIZE") |> String.to_integer()

guardian_secret_key = System.fetch_env!("GUARDIAN_SECRET_KEY")
secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
host = System.fetch_env!("HOST")
app_port_http = System.fetch_env!("APP_PORT_HTTP") |> String.to_integer()

telegram_bot_token = System.fetch_env!("TELEGRAM_BOT_TOKEN")
telegram_port_webhook = System.fetch_env!("TELEGRAM_PORT_WEBHOOK") |> String.to_integer()
webhook_url = System.fetch_env!("WEBHOOK_URL")
telegram_webhook_secret_token = System.fetch_env!("TELEGRAM_WEBHOOK_SECRET_TOKEN")
signing_salt = System.fetch_env!("SIGNING_SALT")
code_reloader_enabled = System.get_env("CODE_RELOADER_ENABLED", "false") == "true"

# --------------------------------------------------------------------------
# Application Configuration
# --------------------------------------------------------------------------

# Configure your database
config :core, Core.Repo,
  username: db_username,
  password: db_password,
  hostname: db_host,
  database: db_name,
  pool_size: pool_size

# Configure the main application
config :admin_api,
  namespace: AdminApi,
  ecto_repos: [Core.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure Guardian for JWT
config :admin_api, AdminApi.Guardian,
  issuer: "telegram_admin_api",
  secret_key: guardian_secret_key,
  ttl: {1, :day},
  refresh_ttl: {30, :days}

# Configure Phoenix Endpoint
config :admin_api, AdminApiWeb.Endpoint,
  url: [host: host, port: app_port_http],
  http: [ip: {0, 0, 0, 0}, port: app_port_http],
  secret_key_base: secret_key_base,
  server: true,
  check_origin: ["//#{host}"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: AdminApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AdminApi.PubSub,
    live_view: [signing_salt: signing_salt]

# Enable code reloader for development
if code_reloader_enabled do
  config :admin_api, AdminApiWeb.Endpoint,
    code_reloader: true
end

# Configure rate limiting
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

# Configure Telegram application
config :telegram_api,
  bot_token: telegram_bot_token

# Configure Telegex webhook handler
config :telegex,
  telegram_port_webhook: telegram_port_webhook,
  hook_adapter: Bandit,
  handler: TelegramApi.HookHandler,
  token: telegram_bot_token,
  webhook_url: webhook_url,
  secret_token: telegram_webhook_secret_token,
  caller_adapter: Finch

# Configure logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

# Configure telemetry poller
config :telemetry_poller,
  measurements: [
    # A module, function and arguments to be invoked periodically.
    # {Core, :count_users, []},
    {TelemetryPoller, :measure, []}
  ],
  period: 10_000
