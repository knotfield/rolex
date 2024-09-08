defmodule Rolex.Repo.Migrations.CreateRolexPermissions do
  use Ecto.Migration

  def change do
    id_type = :binary_id

    create table(:rolex_permissions) do
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
        :rolex_permissions,
        ~w(verb role subject_type subject_id object_type object_id)a,
        name: :rolex_permissions_unique_index,
        nulls_distinct: false
      )
    )

  end
end
