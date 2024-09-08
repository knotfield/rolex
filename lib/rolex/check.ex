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

  def roles_granted(permissions) do
    permissions
    |> Enum.map(& &1.role)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Filters granted permissions per DSL options.
  """
  def filter_granted(permissions, opts) do
    params =
      DSL.changeset_for_filter(opts)
      |> DSL.to_permission_params()

    permissions |> Permission.filter_granted(params)
  end

  @doc """
  Filters granted permissions per DSL options, prefilling `to: subject`.
  """
  @spec filter_granted_to([Permission.t()], any_scope(), [any_role_opt() | any_on_opt()]) ::
          [Permission.t()]
  def filter_granted_to(permissions, subject, opts \\ []) do
    filter_granted(permissions, [{:to, subject} | opts])
  end

  @doc """
  Filters granted permissions per DSL options, prefilling `on: object`.
  """
  @spec filter_granted_on([Permission.t()], any_scope(), [any_role_opt() | any_to_opt()]) ::
          [Permission.t()]
  def filter_granted_on(permissions, object, opts \\ []) do
    filter_granted(permissions, [{:on, object} | opts])
  end

  @doc """
  Returns true if given any granted permissions that meet DSL filtering options.
  """
  @spec granted?([Permission.t()], [any_role_opt() | any_to_opt() | any_on_opt()]) :: boolean()
  def granted?(permissions, opts \\ []) do
    permissions |> filter_granted(opts) |> Enum.any?()
  end

  @doc """
  Returns true if given any granted permissions that meet DSL filtering options, prefilling `role: role`.
  """
  @spec granted_role?([Permission.t()], any_role(), [any_to_opt() | any_on_opt()]) :: boolean()
  def granted_role?(permissions, role, opts \\ []),
    do: granted?(permissions, [{:role, role} | opts])

  @doc """
  Returns true if given any granted permissions that meet DSL filtering options, prefilling `to: subject`.
  """
  @spec granted_to?([Permission.t()], any_scope(), [any_role_opt() | any_on_opt()]) :: boolean()
  def granted_to?(permissions, subject, opts \\ []),
    do: granted?(permissions, [{:to, subject} | opts])

  @doc """
  Returns true if given any granted permissions that meet DSL filtering options, prefilling `on: object`.
  """
  @spec granted_on?([Permission.t()], any_scope(), [any_role_opt() | any_to_opt()]) :: boolean()
  def granted_on?(permissions, object, opts \\ []),
    do: granted?(permissions, [{:on, object} | opts])
end
