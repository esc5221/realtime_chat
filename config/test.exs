import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :realtime_chat, RealtimeChat.Repo,
  database: Path.expand("../realtime_chat_test.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox,
  adapter: Ecto.Adapters.SQLite3

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :realtime_chat, RealtimeChatWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "9bp+aN0juPr2OTNAVs789pfb9qWRID0JoFpNZIePnochBvike7vnzxxV8uGVR+y3",
  server: false

# In test we don't send emails
config :realtime_chat, RealtimeChat.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
