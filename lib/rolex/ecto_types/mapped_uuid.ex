defmodule Rolex.EctoTypes.MappedUUID do
  @moduledoc """
  Custom type to support persisting special atoms as specific "magic" UUIDs.

  Options:

      * `values` - maps atoms to the uuids that represent them in the database;
                   e.g. `[admin: "00000000-0000-0000-0000-000000000000"]`
  """

  use Ecto.ParameterizedType

  @type t :: Ecto.Type.t()

  def init(opts) do
    atom_to_uuid = Enum.into(opts, %{}) |> Map.fetch!(:values) |> Enum.into(%{})
    uuid_to_atom = atom_to_uuid |> Enum.map(fn {k, v} -> {v, k} end) |> Enum.into(%{})

    atom_aliases = atom_to_uuid |> Enum.map(fn {k, _} -> {to_string(k), k} end) |> Enum.into(%{})

    %{atom_to_uuid: atom_to_uuid, uuid_to_atom: uuid_to_atom, atom_aliases: atom_aliases}
  end

  def type(_params), do: :uuid

  # outside data (atom or string) -> runtime data (atom or string)
  def cast(value, %{atom_aliases: atom_aliases} = params) when is_map_key(atom_aliases, value),
    do: cast(atom_aliases[value], params)

  def cast(value, %{atom_to_uuid: atom_to_uuid}) when is_map_key(atom_to_uuid, value),
    do: {:ok, value}

  def cast(value, _params), do: Ecto.UUID.cast(value)

  # database data (uuid) -> runtime data (atom or string)
  def load(value, _loader, %{uuid_to_atom: uuid_to_atom}) do
    with {:ok, uuid} <- Ecto.UUID.load(value) do
      {:ok, Map.get(uuid_to_atom, uuid, uuid)}
    end
  end

  # outside or runtime data (atom or string) -> database data (uuid)
  def dump(nil, _, _), do: {:ok, nil}

  def dump(value, dumper, %{atom_aliases: atom_aliases} = params)
      when is_map_key(atom_aliases, value),
      do: dump(atom_aliases[value], dumper, params)

  def dump(value, _, %{atom_to_uuid: atom_to_uuid}) when is_map_key(atom_to_uuid, value),
    do: Ecto.UUID.dump(atom_to_uuid[value])

  def dump(value, _, _), do: Ecto.UUID.dump(value)
end
