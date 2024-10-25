defmodule Mix.Tasks.Rolex.Regen.Migration do
  @moduledoc false
  # Regenerates the permission table migration for dev and test migration purposes.

  use Mix.Task

  @shortdoc "Regenerates permission table migration"

  @impl true
  def run(_args) do
    table = Application.fetch_env!(:rolex, :table)
    id_type = Application.fetch_env!(:rolex, :id_type)

    [source_file] =
      Mix.Task.run("rolex.gen.migration", [
        table,
        "--id-type",
        id_type,
        "--migrations-path",
        "tmp/migrations"
      ])

    dev_migration_file =
      case Path.wildcard("priv/repo/migrations/*_create_permissions.exs") do
        [path] -> path
        [] -> Path.join("priv/repo/migrations", Path.basename(source_file))
      end

    Mix.shell().info([:green, "* renaming ", :reset, "-> #{dev_migration_file}"])
    :ok = File.rename(source_file, dev_migration_file)
  end
end
