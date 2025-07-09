import Config

# Production configuration for API-only application
config :admin_api, AdminApiWeb.Endpoint,
  url: [port: 443, scheme: "https"],
  http: [
    # Enable IPv6 and bind on all interfaces.
    # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
    # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options.html
    ip: {0, 0, 0, 0, 0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4000")
  ]

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to your endpoint configuration:
#
#     config :admin_api, AdminApiWeb.Endpoint,
#       https: [
#         ...,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SSL_KEYFILE"),
#         certfile: System.get_env("SSL_CERTFILE")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/bandit/Bandit.html#t:options.html

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

# Configure your database
config :core, Core.Repo,
  stacktrace: false,
  show_sensitive_data_on_connection_error: false

# ## Configuring the mailer
#
# In production you need to configure the mailer to use a different adapter.
# Also, you may need to configure the Swoosh API client of your choice if you
# are not using SMTP. Here is an example of the configuration:
#
#     config :admin_api, AdminApi.Mailer,
#       adapter: Swoosh.Adapters.Mailgun,
#       api_key: System.get_env("MAILGUN_API_KEY"),
#       domain: System.get_env("MAILGUN_DOMAIN")
#
# For this example you need include a HTTP client required by Swoosh API client.
# Swoosh supports Hackney and Finch out of the box:
#
#     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
#
# See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
