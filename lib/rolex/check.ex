defmodule Rolex.Check do
  @moduledoc """
  Functions for checking permissions.
  """

  alias Rolex.DSL
  alias Rolex.Permission

  @type any_role :: DSL.any_role()
  @type any_scope :: DSL.any_scope()

  @type any_role_opt :: DSL.any_role_opt()
  @type any_to_opt :: DSL.any_to_opt()
  @type any_on_opt :: DSL.any_on_opt()

  @doc """
  Returns true if any of the given permissions meeting the conditions in `opts` are granted.
  """
  @spec granted?([Permission.t()], [any_role_opt() | any_to_opt() | any_on_opt()]) :: boolean()
  def granted?(permissions, opts \\ []) do
    params =
      DSL.changeset_for_filter(opts)
      |> DSL.to_permission_params()

    permissions |> Permission.filter_granted(params) |> Enum.any?()
  end

  @doc """
  Returns true if any of the given permissions meeting the conditions in `opts` are granted.
  """
  @spec granted_role?([Permission.t()], any_role(), [any_to_opt() | any_on_opt()]) :: boolean()
  def granted_role?(permissions, role, opts \\ []),
    do: granted?(permissions, [{:role, role} | opts])

  @spec granted_to?([Permission.t()], any_scope(), [any_role_opt() | any_on_opt()]) :: boolean()
  def granted_to?(permissions, subject, opts \\ []),
    do: granted?(permissions, [{:to, subject} | opts])

  @spec granted_on?([Permission.t()], any_scope(), [any_role_opt() | any_to_opt()]) :: boolean()
  def granted_on?(permissions, object, opts \\ []),
    do: granted?(permissions, [{:on, object} | opts])
end
