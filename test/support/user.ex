defmodule Rolex.User do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "users" do
    field(:name, :string, default: "some user")

    has_many(:permissions, Rolex.Permission, foreign_key: :subject_id)
  end
end
