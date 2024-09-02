defmodule Mix.Tasks.Rolex.Install do
  use Mix.Task

  import Mix.Generator

  @default_table "permissions"

  @shortdoc "Generates rolex permission table migration"

  @moduledoc """
  Generates a migration to create a permissions table.

  ## Examples

      $ mix rolex.install
      $ mix rolex.install --binary-ids --table "custom_table_name"

  ## Command line options

    * `--binary-ids` - define id fields with `:binary_id` instead of `:id`
    * `--table` - permissions table name, defaults to `#{@default_table}`

  Other options, if any, are passed directly through to the underlying
  `ecto.gen.migration` task used to actually generate the migration.
  """

  @switches [
    binary_ids: :boolean,
    table: :string
  ]

  @impl true
  def run(args) do
    {opts, args, _} =
      OptionParser.parse(args, switches: @switches)

    binding = %{
      binary_ids: opts[:binary_ids],
      table: opts[:table] || @default_table
    }

    Mix.Task.run("ecto.gen.migration", [
      "create_#{binding.table}",
      "--change",
      change_template(binding) | args
    ])
  end

  embed_template(:change, """
      create table(:<%= @table %><%= if @binary_ids do %>, primary_key: false<% end %>) do
  <%= if @binary_ids do %>      add :id, :binary_id, primary_key: true
  <% end %>      add :verb, :string
        add :role, :string
        add :subject_type, :string
        add :subject_id, <%= if @binary_ids, do: ":binary_id", else: ":id" %>
        add :object_type, :string
        add :object_id, <%= if @binary_ids, do: ":binary_id", else: ":id" %>

        timestamps()
      end

      create(
        unique_index(
          :<%= @table %>,
          ~w(verb role subject_type subject_id object_type object_id)a,
          [
            name: :<%= @table %>_unique_index,
            nulls_distinct: true
          ]
        )
      )
  """)
end
