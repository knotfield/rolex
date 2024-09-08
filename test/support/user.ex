defmodule Rolex.User do
  @moduledoc false

  use Ecto.Schema

  @id_type Application.compile_env(:rolex, :id_type, :id)

  @primary_key {:id, @id_type, autogenerate: true}
  schema "users" do
    field(:name, :string, default: "some user")

    has_many(:permissions, Rolex.Permission, foreign_key: :subject_id)
  end
end
