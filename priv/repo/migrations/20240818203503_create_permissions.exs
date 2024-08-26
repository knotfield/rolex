defmodule Rolex.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :verb, :string
      add :role, :string
      add :subject_type, :string
      add :subject_id, :binary_id
      add :object_type, :string
      add :object_id, :binary_id

      timestamps()
    end

    create(
      unique_index(
        :permissions,
        ~w(verb role subject_type subject_id object_type object_id)a,
        [
          name: :permissions_unique_index,
          nulls_distinct: true
        ]
      )
    )
  end
end
