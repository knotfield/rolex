defmodule Rolex.User do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "users" do
    field(:name, :string, default: "some user")

    field(:permissions, {:array, :any}, virtual: true)

    timestamps(type: :utc_datetime)
  end
end
