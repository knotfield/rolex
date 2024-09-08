import Config

config :rolex, Rolex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "rolex_dev",
  stacktrace: true,
  pool_size: 10,
  show_sensitive_data_on_connection_error: true
