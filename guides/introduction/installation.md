# Installing Rolex

Add `rolex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rolex, "~> 0.4.0"}
  ]
end
```

Create and run a migration to set up the `permissions` table.

```shell
$ mix rolex.install --binary-ids
* creating priv/repo/migrations/20240902155226_create_permissions.exs

$ mix ecto.migrate
10:54:04.292 [info] == Running 20240902155226 MyApp.Repo.Migrations.CreatePermissions.change/0 forward
10:54:04.293 [info] create table permissions
10:54:04.301 [info] create index permissions_unique_index
10:54:04.303 [info] == Migrated 20240902155226 in 0.0s
```

Configure Rolex so it knows which Ecto repo to work with and whether your app uses binary IDs.

```elixir
# config.exs
config :rolex, repo: MyApp.Repo, binary_ids: true
```

That's it! You're ready to go.
