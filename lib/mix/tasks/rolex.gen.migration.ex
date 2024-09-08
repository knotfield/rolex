defmodule Mix.Tasks.Rolex.Gen.Migration do
  use Mix.Task

  import Mix.Generator

  @default_table "permissions"

  @shortdoc "Generates rolex permissions table migration"

  @moduledoc """
  Generates a migration to create a permissions table.

  ## Examples

      $ mix rolex.gen.migration
      $ mix rolex.gen.migration "my_custom_table_name"

  Options, if any, are passed directly through to the underlying
  `ecto.gen.migration` task used to actually generate the migration.
  """

  @switches [
    id_type: :string,
    repo: :string,
    no_compile: :boolean,
    no_deps_check: :boolean,
    migrations_path: :string
  ]

  @impl true
  def run(args) do
    {opts, args} = OptionParser.parse!(args, strict: @switches, aliases: [r: :repo])
    {table, []} = List.pop_at(args, 0, @default_table)
    {id_type, opts} = Keyword.pop(opts, :id_type)
    args_to_forward = OptionParser.to_argv(opts)

    assigns = [table: table, id_type: id_type]

    Mix.Task.run("ecto.gen.migration", [
      "create_#{table}",
      "--change",
      change_template(assigns) | args_to_forward
    ])
  end

  embed_template(:change, """
      id_type = <%= if @id_type do %>:<%= @id_type %><% else %>case Map.get(references(:dummy), :type) do
        :binary_id -> :binary_id
        _ -> :id
      end<% end %>

      create table(:<%= @table %>) do
        add(:verb, :string)
        add(:role, :string)
        add(:subject_type, :string)
        add(:subject_id, id_type)
        add(:object_type, :string)
        add(:object_id, id_type)

        timestamps()
      end

      create(
        unique_index(
          :<%= @table %>,
          ~w(verb role subject_type subject_id object_type object_id)a,
          name: :<%= @table %>_unique_index,
          nulls_distinct: false
        )
      )
  """)
end
