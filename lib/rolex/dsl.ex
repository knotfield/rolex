defmodule Rolex.DSL do
  @moduledoc """
  Implements a small domain-specific language ("DSL") for scoping permissions.

  The DSL is defined by a handful of keyword options:

    * `:role` - a plain atom naming the role
    * `:to` - specifies the subject scope; i.e. "who holds the role?"
    * `:on` - specifics the object scope; i.e. "on which resources does the role apply?

  > When revoking permissions, `from` is used in place of `to`, because it reads more naturally.

  Subject and object scopes are specified using any of these values:

    * `:all` - a special atom for granting or denying ALL of something
    * any Ecto schema module; e.g. `MyApp.Users.User`
    * any Ecto schema record; e.g. `%MyApp.Users.User{id: 123}`

  """

  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__, as: DSL

  @all Application.compile_env(:rolex, :all_atom, :all)
  @any Application.compile_env(:rolex, :any_atom, :any)

  @primary_key false
  embedded_schema do
    field(:role, :any, virtual: true)
    field(:from, :any, virtual: true, source: :subject)
    field(:to, :any, virtual: true, source: :subject)
    field(:on, :any, virtual: true, source: :object)
  end

  @type action :: :grant | :deny | :revoke | :filter

  @type role :: atom()
  @type schema :: module()
  @type record :: Ecto.Schema.t()
  @type scope :: :all | schema() | record()

  @type role_opt :: {:role, role()}
  @type from_opt :: {:from, scope()}
  @type to_opt :: {:to, scope()}
  @type on_opt :: {:on, scope()}

  @type any_role :: :any | role()
  @type any_scope :: :any | {:any, schema()} | scope()

  @type any_role_opt :: {:role, any_role()}
  @type any_from_opt :: {:from, any_scope()}
  @type any_to_opt :: {:to, any_scope()}
  @type any_on_opt :: {:on, any_scope()}
  @type revoke_option ::
          {:role, :any | role()} | {:from, :any | scope()} | {:on, :any | scope()}
  @type filter_option ::
          {:role, :any | role()} | {:to, :any | scope()} | {:on, :any | scope()}

  @type t :: %DSL{role: role(), from: scope(), to: scope(), on: scope()}
  @type changeset :: Ecto.Changeset.t(t())

  @doc """
  Returns a new `m:Rolex.DSL` initialized from `input` on success, or `{:error, reason}` otherwise.
  """
  def new(input \\ []) do
    cond do
      match?(%Ecto.Changeset{valid?: false}, input) -> {:error, :invalid_changeset}
      match?(%Ecto.Changeset{data: %DSL{}}, input) -> apply_changes(input)
      match?(%Ecto.Changeset{}, input) -> {:error, :unexpected_changeset}
      Enumerable.impl_for(input) -> struct(DSL, to_atom_keyed_map(input))
    end
  end

  @doc """
  Converts `input` from external DSL options to internal `m:Rolex.Permission` schema params.

  Returns an atom-keyed map on success, or an `{:error, reason}` tuple otherwise.
  """
  @spec to_permission_params(t() | Enumerable.t()) :: map() | {:error, term()}
  def to_permission_params(%DSL{} = input) do
    input
    |> Map.from_struct()
    |> Enum.flat_map(fn
      {_, nil} ->
        []

      {_, @any} ->
        []

      {:role, role} ->
        [role: role]

      {key, value} when key in [:to, :from] ->
        case value do
          @all -> [subject_type: @all, subject_id: @all]
          {@any, type} -> [subject_type: type]
          %{id: id, __struct__: type} -> [subject_type: type, subject_id: id]
          type -> [subject_type: type, subject_id: @all]
        end

      {:on, value} ->
        case value do
          @all -> [object_type: @all, object_id: @all]
          {@any, type} -> [object_type: type]
          %{id: id, __struct__: type} -> [object_type: type, object_id: id]
          type -> [object_type: type, object_id: @all]
        end
    end)
    |> Enum.into(%{})
  end

  def to_permission_params(input) do
    with %DSL{} = dsl <- new(input) do
      to_permission_params(dsl)
    end
  end

  @doc """
  Returns a changeset for DSL options used to perform `action`.

  Action may be any of `:grant`, `:deny`, `:revoke`, `:filter`.
  """
  @spec changeset(action(), keyword()) :: changeset()
  def changeset(action, opts) do
    case action do
      :grant -> %{changeset_for_grant_or_deny(opts) | action: :grant}
      :deny -> %{changeset_for_grant_or_deny(opts) | action: :deny}
      :revoke -> %{changeset_for_revoke(opts) | action: :revoke}
      :filter -> %{changeset_for_filter(opts) | action: :filter}
    end
  end

  @doc """
  Returns a changeset for DSL options used when granting or denying permissions.

  ## Options:

    * `:role` - a plain atom naming a role
    * `:to` - `:all`, schema, or record
    * `:on` - `:all`, schema, or record

  """
  @spec changeset_for_grant_or_deny([role_opt() | to_opt() | on_opt()]) :: changeset()
  def changeset_for_grant_or_deny(opts) do
    %DSL{}
    |> cast(to_atom_keyed_map(opts), [:role, :to, :on])
    |> validate_required([:role, :to, :on])
    |> validate_change_value_type(:role, [:plain_atom])
    |> validate_change_value_type(:to, [:all, :schema, :record])
    |> validate_change_value_type(:on, [:all, :schema, :record])
  end

  @doc """
  Returns a changeset for options used when revoking permissions.

  ## Options:

    * `:role` - a plain atom naming a role, or:
      * `:any` - will match **any** permission role
    * `:from` - `:all`, schema, record, or:
      * `:any` - will match **any** permission subject
      * `{:any, <schema>}` - will match **any** permission subject of the named schema
    * `:on` - `:all`, schema, record, or:
      * `:any` - will match **any** permission object
      * `{:any, <schema>}` - will match **any** permission object of the named schema

  """
  @spec changeset_for_revoke([any_role_opt() | any_from_opt() | any_on_opt()]) :: changeset()
  def changeset_for_revoke(opts) do
    %DSL{}
    |> cast(to_atom_keyed_map(opts), [:role, :from, :on])
    |> validate_required([:role, :from, :on])
    |> validate_change_value_type(:role, [:any, :plain_atom])
    |> validate_change_value_type(:from, [:all, :any, :schema, :any_tuple, :record])
    |> validate_change_value_type(:on, [:all, :any, :schema, :any_tuple, :record])
  end

  @doc """
  Returns a changeset for options used when filtering permissions.

  ## Options:

    * `:role` - a plain atom naming a role, or:
      * `:any` - will match **any** permission role
    * `:to` - `:all`, schema, record, or:
      * `:any` - will match **any** permission subject
      * `{:any, <schema>}` - will match **any** permission subject of the named schema
    * `:on` - `:all`, schema, record, or:
      * `:any` - will match **any** permission object
      * `{:any, <schema>}` - will match **any** permission object of the named schema

  """
  @spec changeset_for_filter([any_role_opt() | any_to_opt() | any_on_opt()]) :: changeset()
  def changeset_for_filter(opts) do
    types = %{role: :any, to: :any, on: :any}
    fields = Map.keys(types)

    %DSL{}
    |> cast(to_atom_keyed_map(opts), fields)
    |> validate_change_value_type(:role, [:any, :plain_atom])
    |> validate_change_value_type(:to, [:all, :any, :schema, :any_tuple, :record])
    |> validate_change_value_type(:on, [:all, :any, :schema, :any_tuple, :record])
  end

  defp to_atom_keyed_map(enumerable) do
    enumerable
    |> Enum.map(fn {k, v} -> {to_string(k) |> String.to_atom(), v} end)
    |> Enum.into(%{})
  end

  defp validate_change_value_type(changeset, field, value_types) do
    validate_change(changeset, field, fn _, value ->
      if value_type(value) in value_types do
        []
      else
        [{field, "is invalid"}]
      end
    end)
  end

  defp value_type(value) do
    cond do
      value == @all -> :all
      value == @any -> :any
      is_atom(value) and not function_exported?(value, :__info__, 1) -> :plain_atom
      is_atom(value) and {:__schema__, 1} in value.__info__(:functions) -> :schema
      is_atom(value) -> :module
      is_struct(value) and value_type(value.__struct__) == :schema -> :record
      match?({@any, _}, value) and value_type(elem(value, 1)) == :schema -> :any_tuple
    end
  end
end
