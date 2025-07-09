import Config

config :logger, level: :info

config :core, Core.Repo,
  stacktrace: false,
  show_sensitive_data_on_connection_error: false
