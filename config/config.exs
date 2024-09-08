import Config

# fed to rolex.gen.migration and rolex config
id_type = :binary_id
table = "rolex_permissions"
# NB. drop and create the test database after changing table names

config :rolex, ecto_repos: [Rolex.Repo], repo: Rolex.Repo, id_type: id_type, table: table

if id_type != :id do
  # this setting controls how migrations set up primary keys --
  # so if we're configuring Rolex to work with something besides the default (`:id`),
  # we need to be specific here.
  config :rolex, Rolex.Repo, migration_primary_key: [name: :id, type: id_type, autogenerate: true]
end

config :mix_test_watch,
  exclude: [~r/\.#/, ~r{tmp/migrations}, ~r{priv/repo/migrations}],
  tasks: [
    # regenerate the migration using the configured id_type
    "rolex.regen.migration #{table}",
    # ... then roll the database back to nothing
    "ecto.rollback --quiet --to 0",
    # ... so that each test run is like a new installation.
    "test"
  ]

import_config "#{config_env()}.exs"
