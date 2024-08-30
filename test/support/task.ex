defmodule Rolex.Task do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "tasks" do
    field(:name, :string, default: "some task")
    timestamps(type: :utc_datetime)
  end
end
