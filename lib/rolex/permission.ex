defmodule Rolex.Permission do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Rolex.EctoTypes.Atom
  alias Rolex.EctoTypes.MappedUUID
  alias __MODULE__, as: Permission

  @all Application.compile_env(:rolex, :all_atom, :all)
  @any Application.compile_env(:rolex, :any_atom, :any)

  @mapped_uuids %{
    @all => Application.compile_env(:rolex, :all_uuid, "11111111-1111-1111-1111-111111111111"),
    @any => Application.compile_env(:rolex, :any_uuid, "00000000-0000-0000-0000-000000000000")
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "permissions" do
    field(:verb, Ecto.Enum, values: [:grant, :deny])
    field(:role, Atom)
    field(:subject_type, Atom, default: @all)
    field(:subject_id, MappedUUID, values: @mapped_uuids, default: @all)
    field(:object_type, Atom, default: @all)
    field(:object_id, MappedUUID, values: @mapped_uuids, default: @all)

    timestamps()
  end

  def changeset(data, params \\ [])

  @fields ~w(verb role subject_type subject_id object_type object_id)a
  def changeset(%Permission{} = data, opts) do
    params = parse_options(opts)

    data
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> reduce_over(@fields, &validate_exclusion(&2, &1, [@any]))
    |> unique_constraint(:role, name: :permissions_unique_index)
  end

  defp reduce_over(acc, enumerable, fun) do
    enumerable |> Enum.reduce(acc, fun)
  end

  @doc """
  Returns a changeset for creating a grant permission.
  """
  def grant_changeset(opts) do
    %Permission{verb: :grant}
    |> changeset(opts)
    |> validate_inclusion(:verb, [:grant])
  end

  @doc """
  Returns a changeset for creating a deny permission.
  """
  def deny_changeset(opts) do
    %Permission{verb: :deny}
    |> changeset(opts)
    |> validate_inclusion(:verb, [:deny])
  end

  @doc """
  Parses options into permission attributes.
  """
  def parse_options(opts, overriding_opts \\ []) do
    [opts, overriding_opts]
    |> Enum.map(&to_option_map/1)
    |> then(fn [a, b] -> Map.merge(a, b) end)
    |> Enum.flat_map(fn
      {_, @any} -> []
      {:verb, verb} when verb in [:grant, :deny] -> [verb: verb]
      {:role, role} when is_atom(role) -> [role: role]
      {:from, @all} -> [subject_type: @all, subject_id: @all]
      {:from, type} when is_atom(type) -> [subject_type: type, subject_id: @all]
      {:from, %{id: id, __struct__: type}} -> [subject_type: type, subject_id: id]
      {:from_all, type} when is_atom(type) -> [subject_type: type, subject_id: @all]
      {:from_any, type} when is_atom(type) -> [subject_type: type, subject_id: @any]
      {:to, @all} -> [subject_type: @all, subject_id: @all]
      {:to, type} when is_atom(type) -> [subject_type: type, subject_id: @all]
      {:to, %{id: id, __struct__: type}} -> [subject_type: type, subject_id: id]
      {:to_all, type} when is_atom(type) -> [subject_type: type, subject_id: @all]
      {:to_any, type} when is_atom(type) -> [subject_type: type, subject_id: @any]
      {:on, @all} -> [object_type: @all, object_id: @all]
      {:on, type} when is_atom(type) -> [object_type: type, object_id: @all]
      {:on, %{id: id, __struct__: type}} -> [object_type: type, object_id: id]
      {:on_all, type} when is_atom(type) -> [object_type: type, object_id: @all]
      {:on_any, type} when is_atom(type) -> [object_type: type, object_id: @any]
    end)
    |> Enum.into(%{})
  end

  defp to_option_map(opts) do
    opts
    |> Enum.map(fn {k, v} -> {to_string(k) |> String.to_atom(), v} end)
    |> Enum.into(%{})
  end

  @doc """
  Returns an initialized `%Ecto.Query{}` to be used for permission queries.
  """
  def base_query do
    from(p in Permission, as: :permission)
  end

  @doc """
  Narrows a permission query to grant permissions that are not overridden by a deny permission.

  ## Options

      * :role - names the granted role
      * :to - the permission subject ("who")
      * :on - the permission object ("what")

  """
  def where_granted(%Ecto.Query{from: %{as: parent_binding}} = query, opts \\ []) do
    query
    |> where_equal_or_all(opts)
    |> where(
      [g],
      g.verb == :grant and
        not exists(
          from(d in query,
            where: d.verb == :deny and d.role in [^@all, field(parent_as(^parent_binding), :role)]
          )
        )
    )
  end

  @doc """
  Narrows a list of permissions to grant permissions that are not overridden by a deny permission.

  ## Options

      * :role - names the granted role
      * :to - the permission subject ("who")
      * :on - the permission object ("what")

  """
  def filter_granted(list, opts \\ []) do
    list
    |> filter_equal_or_all(opts)
    |> Enum.filter(&(&1.verb == :grant))
    |> Enum.reject(fn g ->
      list
      |> Enum.any?(fn d ->
        d.verb == :deny and d.role in [@all, g.role]
      end)
    end)
  end

  @doc """
  Narrows a permission query to those that exactly match the passed parameters.

  Used to target specific records, as when revoking permissions.

  ## Params

      * :role - names the granted role
      * :to - the permission subject ("who")
      * :on - the permission object ("what")

  """
  def where_equal(%Ecto.Query{} = query, opts \\ []) do
    parse_options(opts)
    |> Enum.reduce(query, fn
      {field, value}, query -> where(query, [q], field(q, ^field) == ^value)
    end)
  end

  # Narrows a permission query to those that meet or supersede the passed parameters.
  # Used to identify permissions to be considered, as when checking granted roles.
  defp where_equal_or_all(%Ecto.Query{} = query, opts) do
    parse_options(opts)
    |> Enum.reduce(query, fn
      {_, @any}, query -> query
      {field, value}, query -> where(query, [q], field(q, ^field) in [^@all, ^value])
    end)
  end

  # Narrows a list of permissions to those that meet or supersede the passed parameters.
  # Used to identify permissions to be considered, as when checking granted roles.
  defp filter_equal_or_all(list, opts) do
    params = parse_options(opts)

    list
    |> Enum.filter(fn permission ->
      Enum.all?(params, fn
        {_, @any} -> true
        {field, value} -> Map.get(permission, field) in [@all, value]
      end)
    end)
  end
end
