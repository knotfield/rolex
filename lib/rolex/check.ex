defmodule Rolex.Check do
  @moduledoc """
  Functions for checking permissions.
  """

  alias Rolex.DSL
  alias Rolex.Permission

  @type role :: DSL.role()

  @type any_role :: DSL.any_role()
  @type any_scope :: DSL.any_scope()

  @type any_role_opt :: DSL.any_role_opt()
  @type any_to_opt :: DSL.any_to_opt()
  @type any_on_opt :: DSL.any_on_opt()

  @doc """
  Lists roles granted by given permissions that meet DSL options.
  """
  @spec roles_granted([Permission.t()], [any_role_opt() | any_to_opt() | any_on_opt()]) ::
          [role()]
  def roles_granted(permissions, opts \\ []) do
    permissions
    |> filter_granted(opts)
    |> Enum.map(& &1.role)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Lists roles granted by the given permissions that meet DSL options, prefilling `to: subject`.
  """
  @spec roles_granted_to([Permission.t()], any_scope(), [any_role_opt() | any_on_opt()]) ::
          [role()]
  def roles_granted_to(permissions, subject, opts \\ []) do
    roles_granted(permissions, [{:to, subject} | opts])
  end

  @doc """
  Lists roles granted by the given permissions that meet DSL options, prefilling `on: object`.
  """
  @spec roles_granted_on([Permission.t()], any_scope(), [any_role_opt() | any_to_opt()]) ::
          [role()]
  def roles_granted_on(permissions, object, opts \\ []) do
    roles_granted(permissions, [{:on, object} | opts])
  end

  @doc """
  Returns true if given any granted permissions that meet DSL options.
  """
  @spec granted?([Permission.t()], [any_role_opt() | any_to_opt() | any_on_opt()]) :: boolean()
  def granted?(permissions, opts \\ []) do
    permissions |> roles_granted(opts) |> Enum.any?()
  end

  @doc """
  Returns true if given any granted permissions that meet DSL options, prefilling `role: role`.
  """
  @spec granted_role?([Permission.t()], any_role(), [any_to_opt() | any_on_opt()]) :: boolean()
  def granted_role?(permissions, role, opts \\ []) do
    permissions |> granted?([{:role, role} | opts])
  end

  @doc """
  Returns true if given any granted permissions that meet DSL options, prefilling `to: subject`.
  """
  @spec granted_to?([Permission.t()], any_scope(), [any_role_opt() | any_on_opt()]) :: boolean()
  def granted_to?(permissions, subject, opts \\ []) do
    granted?(permissions, [{:to, subject} | opts])
  end

  @doc """
  Returns true if given any granted permissions that meet DSL options, prefilling `on: object`.
  """
  @spec granted_on?([Permission.t()], any_scope(), [any_role_opt() | any_to_opt()]) :: boolean()
  def granted_on?(permissions, object, opts \\ []) do
    granted?(permissions, [{:on, object} | opts])
  end

  # filters granted permissions per DSL options.
  @spec filter_granted([Permission.t()], [any_role_opt() | any_to_opt() | any_on_opt()]) ::
          [Permission.t()]
  defp filter_granted(permissions, opts) do
    params =
      DSL.changeset_for_filter(opts)
      |> DSL.to_permission_params()

    permissions |> Permission.filter_granted(params)
  end
end
