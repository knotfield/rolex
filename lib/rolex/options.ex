defmodule Rolex.Options do
  @moduledoc """
  A module for validating options for permission-related actions.

  These options make up a small domain-specific language ("DSL").

  The grammar has three terms for scoping permissions:

      * `:all` - a special atom for granting or denying ALL of something
      * module - any module that defines a struct with an `id` field
      * entity - any struct with an `id` key; e.g. `%User{id: 123}`

  And only three* keywords:

      * `role: <atom>` - any atom except `:all` or `:any`
      * `to: <subject>` - what scope is being granted the role?
      * `on: <object>` - which resources are being granted?

  * When revoking permissions, `from` is used in place of `to`
  """

  import Ecto.Changeset

  alias Rolex.EctoTypes.Atom

  @any Application.compile_env(:rolex, :any_atom, :any)

  @doc """
  Validates options for performing `action`.
  """
  def changeset(action, opts \\ []) do
    case action do
      :grant -> creating_changeset(opts)
      :deny -> creating_changeset(opts)
      :revoke -> deleting_changeset(opts)
      :filter -> filtering_changeset(opts)
    end
  end

  @doc """
  Returns a changeset for options used when creating permissions.

  Options:

      * `role` - an atom
      * `to` - `:all`, a module, or a struct with an `id` key
      * `on` - `:all`, a module, or a struct with an `id` key

  """
  def creating_changeset(opts) do
    types = %{role: Atom, to: :any, on: :any}
    fields = Map.keys(types)

    {%{}, types}
    |> cast(to_atom_keyed_map(opts), fields)
    |> reduce_over(fields, &validate_exclusion(&2, &1, [@any]))
    |> validate_required([:role, :to, :on])
  end

  @doc """
  Returns a changeset for options used when revoking permissions.

  Options:

      * `role` - an atom
      * `from` - `:all`, a module, a struct with an `id` key, or:
        * `:any` - will match ANY permission subject
        * `{:any, <module>}` - will match ANY permission subject of the named type
      * `on` - `:all`, a module, a struct with an `id` key, or:
        * `:any` - will match ANY permission object
        * `{:any, <module>}` - will match ANY permission object of the named type

  """
  def deleting_changeset(opts) do
    types = %{role: Atom, from: :any, on: :any}
    fields = Map.keys(types)

    {%{}, types}
    |> cast(to_atom_keyed_map(opts), fields)
    |> reduce_over(fields, &validate_exclusion(&2, &1, [@any]))
    |> validate_required([:role, :from, :on])
  end

  @doc """
  Returns a changeset for options used when filtering permissions.

  Options:

      * `role` - an atom
      * `from` - `:all`, a module, a struct with an `id` key, or:
        * `:any` - will match ANY permission subject
        * `{:any, <module>}` - will match ANY permission subject of the named type
      * `on` - `:all`, a module, a struct with an `id` key, or:
        * `:any` - will match ANY permission object
        * `{:any, <module>}` - will match ANY permission object of the named type

  """
  def filtering_changeset(opts) do
    types = %{role: Atom, to: :any, on: :any}
    fields = Map.keys(types)

    {%{}, types}
    |> cast(to_atom_keyed_map(opts), fields)
    |> validate_required([:role, :to, :on])
  end

  defp reduce_over(acc, enumerable, fun) do
    enumerable |> Enum.reduce(acc, fun)
  end

  defp to_atom_keyed_map(enumerable) do
    enumerable
    |> Enum.map(fn {k, v} -> {to_string(k) |> String.to_atom(), v} end)
    |> Enum.into(%{})
  end
end
