defmodule Rolex.Options do
  @moduledoc """
  A module for validating options for permission-related actions.

  These options make up a small domain-specific language ("DSL").

  The grammar has three terms for scoping permissions:

      * `:all` - a special atom for granting or denying ALL of something
      * schema - any Ecto schema module
      * entity - any Ecto schema entity; e.g. `%User{id: 123}`

  And only three* keywords:

      * `role: <atom>` - any atom except `:all` or `:any`
      * `to: <subject>` - what scope is being granted the role?
      * `on: <object>` - which resources are being granted?

  * When revoking permissions, `from` is used in place of `to`
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__, as: Options

  @all Application.compile_env(:rolex, :all_atom, :all)
  @any Application.compile_env(:rolex, :any_atom, :any)

  @primary_key false
  embedded_schema do
    field(:role, :any, virtual: true)
    field(:from, :any, virtual: true, source: :subject)
    field(:to, :any, virtual: true, source: :subject)
    field(:on, :any, virtual: true, source: :object)
  end

  def new(input \\ []) do
    cond do
      match?(%Ecto.Changeset{valid?: false}, input) -> {:error, :invalid_changeset}
      match?(%Ecto.Changeset{data: %Options{}}, input) -> apply_changes(input)
      match?(%Ecto.Changeset{}, input) -> {:error, :unexpected_changeset}
      Enumerable.impl_for(input) -> struct(Options, to_atom_keyed_map(input))
    end
  end

  @doc """
  Converts `options` from external DSL to internal params.

  Returns an atom-keyed map on success, or an `{:error, reason}` tuple otherwise.

  This is the bit that provides the boundary between the Rolex DSL (to/from/on) and actual permission fields.
  """
  def to_permission_params(%Options{} = options) do
    options
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
    with %Options{} = options <- new(input) do
      to_permission_params(options)
    end
  end

  @doc """
  Validates options for performing `action`.
  """
  def changeset(action, opts \\ []) do
    case action do
      :grant -> changeset_for_grant_or_deny(opts)
      :deny -> changeset_for_grant_or_deny(opts)
      :revoke -> changeset_for_revoke(opts)
      :filter -> changeset_for_filter(opts)
    end
  end

  @doc """
  Returns a changeset for options used when creating permissions.

  Options:

      * `role` - a plain atom naming a role
      * `to` - `:all`, schema, or entity
      * `on` - `:all`, schema, or entity

  """
  def changeset_for_grant_or_deny(opts) do
    %Options{}
    |> cast(to_atom_keyed_map(opts), [:role, :to, :on])
    |> validate_required([:role, :to, :on])
    |> validate_change_value_type(:role, [:plain_atom])
    |> validate_change_value_type(:to, [:all, :schema, :entity])
    |> validate_change_value_type(:on, [:all, :schema, :entity])
  end

  @doc """
  Returns a changeset for options used when revoking permissions.

  Options:

      * `role` - a plain atom naming a role, or:
        * `:any` - will match ANY permission role
      * `from` - `:all`, schema, entity, or:
        * `:any` - will match ANY permission subject
        * `{:any, <schema>}` - will match ANY permission subject of the named schema
      * `on` - `:all`, schema, entity, or:
        * `:any` - will match ANY permission object
        * `{:any, <schema>}` - will match ANY permission object of the named schema

  """
  def changeset_for_revoke(opts) do
    %Options{}
    |> cast(to_atom_keyed_map(opts), [:role, :from, :on])
    |> validate_required([:role, :from, :on])
    |> validate_change_value_type(:role, [:any, :plain_atom])
    |> validate_change_value_type(:from, [:all, :any, :schema, :any_tuple, :entity])
    |> validate_change_value_type(:on, [:all, :any, :schema, :any_tuple, :entity])
  end

  @doc """
  Returns a changeset for options used when filtering permissions.

  Options:

      * `role` - a plain atom naming a role, or:
        * `:any` - will match ANY permission role
      * `to` - `:all`, schema, entity, or:
        * `:any` - will match ANY permission subject
        * `{:any, <schema>}` - will match ANY permission subject of the named type
      * `on` - `:all`, schema, entity, or:
        * `:any` - will match ANY permission object
        * `{:any, <schema>}` - will match ANY permission object of the named type

  """
  def changeset_for_filter(opts) do
    types = %{role: :any, to: :any, on: :any}
    fields = Map.keys(types)

    %Options{}
    |> cast(to_atom_keyed_map(opts), fields)
    |> validate_change_value_type(:role, [:any, :plain_atom])
    |> validate_change_value_type(:to, [:all, :any, :schema, :any_tuple, :entity])
    |> validate_change_value_type(:on, [:all, :any, :schema, :any_tuple, :entity])
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
      is_struct(value) and value_type(value.__struct__) == :schema -> :entity
      match?({@any, _}, value) and value_type(elem(value, 1)) == :schema -> :any_tuple
    end
  end
end
