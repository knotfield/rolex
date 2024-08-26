import Config

config :rolex, repo: Rolex.Repo

config :rolex, ecto_repos: [Rolex.Repo]

config :rolex, Rolex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "rolex_dev",
  migration_primary_key: [name: :id, type: :binary_id, autogenerate: true],
  stacktrace: true,
  pool_size: 10,
  show_sensitive_data_on_connection_error: true
