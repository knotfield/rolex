defmodule Rolex.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :name, :string

      timestamps()
    end
  end
end
