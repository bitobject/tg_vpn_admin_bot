import Config

config :logger, level: :debug

config :core, Core.Repo,
  stacktrace: false,
  show_sensitive_data_on_connection_error: false
