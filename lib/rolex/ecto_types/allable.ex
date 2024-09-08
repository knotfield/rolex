defmodule Rolex.EctoTypes.Allable do
  @moduledoc false

  # Custom type that maps runtime @all to database nil (and vice versa)
  # Anything else is cast/loaded/dumped according to its configured `type`; e.g.
  #
  # schema "some_table" do
  #   field :whatever, Allable, type: Ecto.UUID
  # end

  use Ecto.ParameterizedType

  @type t :: Ecto.Type.t()

  @all Application.compile_env(:rolex, :all_atom, :all)

  def init(opts), do: Enum.into(opts, %{}) |> validate_params!()
  defp validate_params!(%{type: _} = params), do: params

  def type(%{type: type}), do: type

  # outside data (atom or string) -> runtime data (atom or string)
  def cast(value, _params) when value in [nil, @all], do: {:ok, @all}
  def cast(value, %{type: type}), do: Ecto.Type.cast(type, value)

  # database data (uuid) -> runtime data (atom or string)
  def load(value, _loader, _params) when value in [nil, @all], do: {:ok, @all}
  def load(value, _loader, %{type: type}), do: Ecto.Type.load(type, value)

  # outside or runtime data (atom or string) -> database data (uuid)
  def dump(value, _dumper, _params) when value in [nil, @all], do: {:ok, nil}
  def dump(value, _dumper, %{type: type}), do: Ecto.Type.dump(type, value)
end
