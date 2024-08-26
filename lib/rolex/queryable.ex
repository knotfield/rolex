defmodule Rolex.Queryable do
  @moduledoc """
  Use this module to add role-based query scoping functions to a context.
  """

  import Ecto.Query

  alias Rolex.Permission

  @all Application.compile_env(:rolex, :all_atom, :all)

  def list_roles_granted(list, opts) do
    list |> Permission.filter_granted(opts) |> Enum.map(& &1.role)
  end

  def list_roles_granted_to(list, subject, opts \\ []) do
    list |> list_roles_granted([{:to, subject} | opts])
  end

  def list_roles_granted_on(list, object, opts \\ []) do
    list |> list_roles_granted([{:on, object} | opts])
  end

  @doc """
  Scopes `query` to records that are the subject ("who") of a granted permission.

  Permission scope itself is controlled by `opts`.

  ## Options

      * :role - names the granted role
      * :on - the permission object ("what")

  ## Examples

      # users where :some_role is granted on a particular task
      iex> from(u in User) |> where_granted_to(role: :some_role, on: task)
  """
  def where_granted_to(%Ecto.Query{} = query, opts \\ []) do
    where_granted(query, opts, :subject_id)
  end

  @doc """
  Scopes `query` to records that are the object ("what") of a granted permission.

  Permission scope itself is controlled by `opts`.

  ## Options

      * :role - names the granted role
      * :to - the permission subject ("who")

  ## Examples

      # tasks where :some_role is granted to a particular user
      iex> from(t in Task) |> where_granted_on(role: :some_role, to: user)
  """
  def where_granted_on(%Ecto.Query{} = query, opts \\ []) do
    where_granted(query, opts, :object_id)
  end

  defp where_granted(%Ecto.Query{} = query, opts, id_field) do
    permissions =
      Permission.base_query()
      |> Permission.where_granted(opts)
      |> distinct([p], field(p, ^id_field))

    from(q in query,
      inner_join: p in subquery(permissions),
      on: field(p, ^id_field) in [^@all, q.id]
    )
  end
end
