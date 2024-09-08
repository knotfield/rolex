defmodule Rolex.Permission do
  @moduledoc """
  Permissions are the basic units of role assignments.

  A permission is an intersection of four pieces of information:

    * verb - either "grant" or "deny"
    * role - the role being granted or denied
    * subject - the entity (or entities) being granted or denied the role
    * object - the entity (or entities) on which the subject is being granted the role

  For example, a permission that "grants admin to user 42 on all tasks" would look like this:

  ```elixir
  %Permission{verb: :grant, role: :admin, subject_type: User, subject_id: 42, object_type: Task, object_id: :all}
  ```

  A permission "applies" to any arbitrary subject and/or object if the corresponding `_type` and `_id`
  fields are either `:all` or a perfect match. This particular permission applies only if the subject
  is specifically `%User{id: 42}` *and* the object is a task; e.g. `%Task{id: 123}`.

  Rolex inspects the full set of applicable permissions to make a final determination about each
  role. If this were the only permission, with subject `%User{id: 42}` and object `%Task{id: _}`,
  the `:admin` role is granted.

  We can make exceptions by creating "deny" permissions. Continuing our example, suppose we
  now wanted to "deny admin to all subjects on task 99".

  ```elixir
  %Permission{verb: :deny, role: :admin, subject_type: :all, subject_id: :all, object_type: Task, object_id: 99}
  ```

  This permission applies to *all* subjects (regardless of type or id!), but only if the object is
  specifically `%Task{id: 99}`.

  Given these two permissions, with subject `%User{id: 42}` and object `%Task{id: 123}`, the `:admin`
  role is granted. In object `%Task{id: 99}`'s case, however, the "deny" permission takes precedence,
  and the `:admin` role will *never* be granted.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Rolex.EctoTypes.Allable
  alias Rolex.EctoTypes.Atom
  alias __MODULE__, as: Permission

  @all Application.compile_env(:rolex, :all_atom, :all)
  @any Application.compile_env(:rolex, :any_atom, :any)
  @table Application.compile_env(:rolex, :table, "permissions")
  @id_type Application.compile_env(:rolex, :id_type, :id)

  @primary_key {:id, @id_type, autogenerate: true}
  schema @table do
    field(:verb, Ecto.Enum, values: [:grant, :deny])
    field(:role, Atom)
    field(:subject_type, Allable, type: Atom)
    field(:subject_id, Allable, type: @id_type)
    field(:object_type, Allable, type: Atom)
    field(:object_id, Allable, type: @id_type)

    timestamps()
  end

  @type action :: :grant | :deny | :revoke

  @typep verb :: :grant | :deny
  @typep role :: atom()
  @typep scope_type :: nil | atom()
  @typep scope_id :: nil | String.t() | integer()

  @opaque t :: %Permission{
            verb: verb(),
            role: role(),
            subject_type: scope_type(),
            subject_id: scope_id(),
            object_type: scope_type(),
            object_id: scope_id()
          }

  @type changeset :: Ecto.Changeset.t(t())

  @type params :: %{
          optional(:verb) => verb(),
          optional(:role) => role(),
          optional(:subject_type) => scope_type(),
          optional(:subject_id) => scope_id(),
          optional(:object_type) => scope_type(),
          optional(:object_id) => scope_id()
        }

  @fields ~w(verb role subject_type subject_id object_type object_id)a

  @doc false
  @spec changeset(t(), params()) :: changeset()
  def changeset(%Permission{} = data, params) do
    data
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> reduce_over(@fields, &validate_exclusion(&2, &1, [@any]))
    |> unique_constraint(:role, name: :"#{@table}_unique_index")
  end

  defp reduce_over(acc, enumerable, fun) do
    enumerable |> Enum.reduce(acc, fun)
  end

  @doc false
  @spec changeset_and_upsert_options(:grant | :deny, params()) :: {changeset(), keyword()}
  def changeset_and_upsert_options(verb, params) when verb in [:grant, :deny] do
    changeset =
      %Permission{verb: verb}
      |> changeset(params)
      |> validate_inclusion(:verb, [verb])

    options = [
      on_conflict: [set: [verb: verb]],
      conflict_target: @fields,
      returning: true
    ]

    {changeset, options}
  end

  @doc """
  Returns an initialized `%Ecto.Query{}` to be used for permission queries.
  """
  @spec base_query() :: Ecto.Query.t()
  def base_query do
    from(p in Permission, as: :permission)
  end

  @doc """
  Narrows a permission query to grant permissions that are not overridden by a deny permission.
  """
  @spec where_granted(Ecto.Query.t(), params()) :: Ecto.Query.t()
  def where_granted(%Ecto.Query{from: %{as: parent_binding}} = query, params \\ %{}) do
    query
    |> where_equal_or_all(params)
    |> where(
      [g],
      g.verb == :grant and
        not exists(
          from(d in query,
            where:
              d.verb == :deny and
                (is_nil(d.role) or
                   d.role == field(parent_as(^parent_binding), :role))
          )
        )
    )
  end

  @doc """
  Narrows a list of permissions to grant permissions that are not overridden by a deny permission.
  """
  @spec filter_granted([t()], params()) :: [t()]
  def filter_granted(list, params \\ %{}) do
    list
    |> filter_equal_or_all(params)
    |> Enum.filter(&(&1.verb == :grant))
    |> Enum.reject(fn g ->
      list
      |> Enum.any?(fn d ->
        d.verb == :deny and d.role in [@all, g.role]
      end)
    end)
  end

  @doc """
  Narrows a permission query to those that match the passed parameters.

  Used to target specific records, as when revoking permissions.
  """
  @spec where_equal(Ecto.Query.t(), params()) :: Ecto.Query.t()
  def where_equal(%Ecto.Query{} = query, params \\ %{}) do
    Enum.reduce(params, query, fn
      {field, @all}, query -> where(query, [q], is_nil(field(q, ^field)))
      {field, value}, query -> where(query, [q], field(q, ^field) == ^value)
    end)
  end

  # Narrows a permission query to those that meet or supersede the passed parameters.
  # Used to identify permissions to be considered, as when checking granted roles.
  defp where_equal_or_all(%Ecto.Query{} = query, params) do
    Enum.reduce(params, query, fn
      {_, @any}, query ->
        query

      {field, @all}, query ->
        where(query, [q], is_nil(field(q, ^field)))

      {field, value}, query ->
        where(query, [q], is_nil(field(q, ^field)) or field(q, ^field) == ^value)
    end)
  end

  # Narrows a list of permissions to those that meet or supersede the passed parameters.
  # Used to identify permissions to be considered, as when checking granted roles.
  defp filter_equal_or_all(list, params) do
    list
    |> Enum.filter(fn permission ->
      Enum.all?(params, fn
        {_, @any} -> true
        {field, value} -> Map.get(permission, field) in [@all, value]
      end)
    end)
  end

  def preloader_query(parent_ids, %Ecto.Association.Has{
        cardinality: :many,
        related: Permission,
        related_key: id_key,
        owner: owner
      }) do
    type_key =
      case id_key do
        :subject_id -> :subject_type
        :object_id -> :object_type
      end

    from(
      x in fragment(
        "select unnest(?) as ?",
        type(^parent_ids, {:array, ^@id_type}),
        literal(^to_string(id_key))
      ),
      join: p in ^base_query(),
      on:
        (field(p, ^type_key) == ^owner or is_nil(field(p, ^type_key))) and
          (field(p, ^id_key) == field(x, ^id_key) or is_nil(field(p, ^id_key))),
      select: p,
      select_merge: %{^id_key => type(field(x, ^id_key), ^@id_type)}
    )
  end

  defimpl Inspect do
    def inspect(permission, _opts) do
      words =
        [
          permission.verb,
          permission.role,
          subject_or_object_to_string("to", permission.subject_type, permission.subject_id),
          subject_or_object_to_string("on", permission.object_type, permission.object_id)
        ]
        |> Enum.filter(& &1)
        |> Enum.join(" ")
        |> String.trim()

      "%Rolex.Permission<#{words}>"
    end

    defp subject_or_object_to_string(opt, type, id) do
      type_string = inspect(type) |> String.trim_leading("Elixir.")

      case {type, id} do
        {nil, nil} -> nil
        {:all, :all} -> "#{opt} all"
        {_, :all} -> "#{opt} #{type_string}"
        {_, id} -> "#{opt} #{type_string} #{id}"
      end
    end
  end
end
