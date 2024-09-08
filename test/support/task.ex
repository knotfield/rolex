defmodule Rolex.Task do
  @moduledoc false

  use Ecto.Schema

  @id_type Application.compile_env(:rolex, :id_type)

  @primary_key {:id, @id_type, autogenerate: true}
  schema "tasks" do
    field(:name, :string, default: "some task")
  end
end
