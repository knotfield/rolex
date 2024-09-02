import Config

config :rolex, repo: Rolex.Repo, binary_ids: true

config :rolex, ecto_repos: [Rolex.Repo]

config :rolex, Rolex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "rolex_test#{System.get_env("MIX_TEST_PARTITION")}",
  migration_primary_key: [name: :id, type: :binary_id, autogenerate: true],
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
