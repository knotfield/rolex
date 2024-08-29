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

  import Ecto.Changeset

  @all Application.compile_env(:rolex, :all_atom, :all)
  @any Application.compile_env(:rolex, :any_atom, :any)

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
    types = %{role: :any, to: :any, on: :any}
    fields = Map.keys(types)

    {%{}, types}
    |> cast(to_atom_keyed_map(opts), fields)
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
    types = %{role: :any, from: :any, on: :any}
    fields = Map.keys(types)

    {%{}, types}
    |> cast(to_atom_keyed_map(opts), fields)
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

    {%{}, types}
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
