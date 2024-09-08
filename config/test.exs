import Config

config :rolex, Rolex.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "rolex_test#{System.get_env("MIX_TEST_PARTITION")}",
  log: false,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
