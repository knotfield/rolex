defmodule Rolex.Queryable do
  @moduledoc """
  Provides role-based query scoping functions.
  """

  import Ecto.Query

  alias Rolex.DSL
  alias Rolex.Permission

  @type any_role_opt :: DSL.any_role_opt()
  @type any_to_opt :: DSL.any_to_opt()
  @type any_on_opt :: DSL.any_on_opt()

  @doc """
  Scopes `query` to records that are the subject ("who") of a granted permission.

  Role and object scope are narrowed by DSL options.

  ## Options

    * `:role` - names the granted role
    * `:on` - the permission object ("what")

  ## Examples

      # users where :some_role is granted on a particular task
      iex> from(u in User) |> where_granted_to(role: :some_role, on: task)
  """
  @spec where_granted_to(Ecto.Queryable.t(), [any_role_opt() | any_on_opt()]) :: Ecto.Query.t()
  def where_granted_to(queryable, opts \\ []) do
    where_granted(queryable, opts, :subject_id)
  end

  @doc """
  Scopes `query` to records that are the object ("what") of a granted permission.

  Role and subject scope are narrowed by DSL options.

  ## Options

    * `:role` - names the granted role
    * `:to` - the permission subject ("who")

  ## Examples

      # tasks where :some_role is granted to a particular user
      iex> from(t in Task) |> where_granted_on(role: :some_role, to: user)
  """
  @spec where_granted_on(Ecto.Queryable.t(), [any_role_opt() | any_to_opt()]) :: Ecto.Query.t()
  def where_granted_on(queryable, opts \\ []) do
    where_granted(queryable, opts, :object_id)
  end

  defp where_granted(queryable, opts, id_field) do
    params =
      DSL.changeset_for_filter(opts)
      |> DSL.to_permission_params()

    permissions =
      Permission.base_query()
      |> Permission.where_granted(params)
      |> distinct([p], field(p, ^id_field))

    from(q in queryable,
      inner_join: p in subquery(permissions),
      on: is_nil(field(p, ^id_field)) or field(p, ^id_field) == q.id
    )
  end
end
