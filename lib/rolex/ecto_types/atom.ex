defmodule Rolex.EctoTypes.Atom do
  @moduledoc false

  # Custom type for persisting atoms

  use Ecto.Type

  @type t :: Ecto.Type.t()

  def type, do: :string

  def cast(value) when is_atom(value), do: {:ok, value}
  def cast(_), do: :error

  def load(value), do: {:ok, String.to_atom(value)}

  def dump(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def dump(_), do: :error
end
