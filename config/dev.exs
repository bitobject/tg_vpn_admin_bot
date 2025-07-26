import Config

config :core, Core.Repo,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :admin_api, AdminApiWeb.Endpoint,
  check_origin: false,
  code_reloader: true,
  debug_errors: true

config :admin_api, :code_reloader,
  watch_paths: [
    "../../lib",
    "../../priv",
    "../../config",
    "../../test"
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix,
  stacktrace_depth: 20,
  plug_init_mode: :runtime
