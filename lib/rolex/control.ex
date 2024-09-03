defmodule Rolex.Control do
  @moduledoc """
  Provides functions for granting, denying, and revoking permissions.
  """

  alias Rolex.DSL
  alias Rolex.Permission

  @type role :: DSL.role()
  @type scope :: DSL.scope()

  @type role_opt :: DSL.role_opt()
  @type from_opt :: DSL.from_opt()
  @type to_opt :: DSL.to_opt()
  @type on_opt :: DSL.on_opt()

  @type any_role :: DSL.any_role()
  @type any_scope :: DSL.any_scope()

  @type any_role_opt :: DSL.any_role_opt()
  @type any_from_opt :: DSL.any_from_opt()
  @type any_to_opt :: DSL.any_to_opt()
  @type any_on_opt :: DSL.any_on_opt()

  @type multi() :: Ecto.Multi.t()

  @doc """
  Creates a role-granting permission from DSL options.

  Returns `:ok` on success, or `{:error, reason}` otherwise.
  """
  @spec grant([role_opt() | to_opt() | on_opt()]) :: :ok | {:error, term()}
  def grant(opts \\ []), do: apply_to_repo(:grant, opts)

  @doc """
  Creates a role-granting permission from DSL options.

  Returns `:ok` on success, or raises an exception otherwise.
  """
  @spec grant!([role_opt() | to_opt() | on_opt()]) :: :ok
  def grant!(opts \\ []), do: grant(opts) |> ok!()

  defp grant(return_value, opts), do: grant(opts) |> ok(return_value)
  defp grant!(return_value, opts), do: grant(opts) |> ok!(return_value)

  @doc """
  Creates a role-granting permission from DSL options, prefilling `role: role`.

  Returns `{:ok, role}` on success, or `{:error, reason}` otherwise.
  """
  @spec grant_role(role(), [to_opt() | on_opt()]) :: {:ok, role()} | {:error, term()}
  def grant_role(role, opts \\ []), do: grant(role, [{:role, role} | opts])

  @doc """
  Creates a role-granting permission from DSL options, prefilling `role: role`.

  Returns `role` on success, or raises an exception otherwise.
  """
  @spec grant_role!(role(), [to_opt() | on_opt()]) :: role()
  def grant_role!(role, opts \\ []), do: grant!(role, [{:role, role} | opts])

  @doc """
  Creates a role-granting permission from DSL options, prefilling `to: subject`.

  Returns `{:ok, subject}` on success, or `{:error, reason}` otherwise.
  """
  @spec grant_to(scope(), [role_opt() | on_opt()]) :: {:ok, scope()} | {:error, term()}
  def grant_to(subject, opts \\ []), do: grant(subject, [{:to, subject} | opts])

  @doc """
  Creates a role-granting permission from DSL options, prefilling `to: subject`.

  Returns `subject` on success, or raises an exception otherwise.
  """
  @spec grant_to!(scope(), [role_opt() | on_opt()]) :: scope()
  def grant_to!(subject, opts \\ []), do: grant!(subject, [{:to, subject} | opts])

  @doc """
  Creates a role-granting permission from DSL options, prefilling `on: object`.

  Returns `{:ok, object}` on success, or `{:error, reason}` otherwise.
  """
  @spec grant_on(scope(), [role_opt() | to_opt()]) :: {:ok, scope()} | {:error, term()}
  def grant_on(object, opts \\ []), do: grant(object, [{:on, object} | opts])

  @doc """
  Creates a role-granting permission from DSL options, prefilling `on: object`.

  Returns `object` on success, or raises an exception otherwise.
  """
  @spec grant_on!(scope(), [role_opt() | to_opt()]) :: scope()
  def grant_on!(object, opts \\ []), do: grant!(object, [{:on, object} | opts])

  @doc """
  Creates a role-denying permission from DSL options.

  Returns `:ok` on success, or `{:error, reason}` otherwise.
  """
  @spec deny([role_opt() | to_opt() | on_opt()]) :: :ok | {:error, term()}
  def deny(opts \\ []), do: apply_to_repo(:deny, opts)

  @doc """
  Creates a role-denying permission from DSL options.

  Returns `:ok` on success, or raises an exception otherwise.
  """
  @spec deny!([role_opt() | to_opt() | on_opt()]) :: :ok
  def deny!(opts \\ []), do: deny(opts) |> ok!()

  defp deny(return_value, opts), do: deny(opts) |> ok(return_value)
  defp deny!(return_value, opts), do: deny(opts) |> ok!(return_value)

  @doc """
  Creates a role-denying permission from DSL options, prefilling `role: role`.

  Returns `{:ok, role}` on success, or `{:error, reason}` otherwise.
  """
  @spec deny_role(role(), [to_opt() | on_opt()]) :: {:ok, role()} | {:error, term()}
  def deny_role(role, opts \\ []), do: deny(role, [{:role, role} | opts])

  @doc """
  Creates a role-denying permission from DSL options, prefilling `role: role`.

  Returns `role` on success, or raises an exception otherwise.
  """
  @spec deny_role!(role(), [to_opt() | on_opt()]) :: role()
  def deny_role!(role, opts \\ []), do: deny!(role, [{:role, role} | opts])

  @doc """
  Creates a role-denying permission from DSL options, prefilling `to: subject`.

  Returns `{:ok, subject}` on success, or `{:error, reason}` otherwise.
  """
  @spec deny_to(scope(), [role_opt() | on_opt()]) :: {:ok, scope()} | {:error, term()}
  def deny_to(subject, opts \\ []), do: deny(subject, [{:to, subject} | opts])

  @doc """
  Creates a role-denying permission from DSL options, prefilling `to: subject`.

  Returns `subject` on success, or raises an exception otherwise.
  """
  @spec deny_to!(scope(), [role_opt() | on_opt()]) :: scope()
  def deny_to!(subject, opts \\ []), do: deny!(subject, [{:to, subject} | opts])

  @doc """
  Creates a role-denying permission from DSL options, prefilling `on: object`.

  Returns `{:ok, object}` on success, or `{:error, reason}` otherwise.
  """
  @spec deny_on(scope(), [role_opt() | to_opt()]) :: {:ok, scope()} | {:error, term()}
  def deny_on(object, opts \\ []), do: deny(object, [{:on, object} | opts])

  @doc """
  Creates a role-denying permission from DSL options, prefilling `on: object`.

  Returns `object` on success, or raises an exception otherwise.
  """
  @spec deny_on!(scope(), [role_opt() | to_opt()]) :: scope()
  def deny_on!(object, opts \\ []), do: deny!(object, [{:on, object} | opts])

  @doc """
  Deletes all permissions matching the given DSL options.

  Returns `{:ok, <number-deleted>}` on success, or `{:error, changeset}` otherwise.
  """
  @spec revoke([any_role_opt() | any_from_opt() | any_on_opt()]) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def revoke(opts \\ []) do
    with {count, _} when is_integer(count) <- apply_to_repo(:revoke, opts) do
      {:ok, count}
    end
  end

  @doc """
  Deletes all permissions matching the given DSL options.

  Returns the number of permissions deleted on success, or raises an exception otherwise.
  """
  @spec revoke!([any_role_opt() | any_from_opt() | any_on_opt()]) :: non_neg_integer()
  def revoke!(opts \\ []), do: revoke(opts) |> ok!()

  defp revoke(return_value, opts), do: revoke(opts) |> ok(return_value)
  defp revoke!(return_value, opts), do: revoke(opts) |> ok!(return_value)

  @doc """
  Deletes all permissions matching the given DSL options, prefilling `role: role`.

  Returns `{:ok, role}` on success, or `{:error, reason}` otherwise.
  """
  @spec revoke_role(any_role(), [any_from_opt() | any_on_opt()]) ::
          {:ok, any_role()} | {:error, term()}
  def revoke_role(role, opts \\ []), do: revoke(role, [{:role, role} | opts])

  @doc """
  Deletes all permissions matching the given DSL options, prefilling `role: role`.

  Returns `role` on success, or raises an exception otherwise.
  """
  @spec revoke_role!(any_role(), [any_from_opt() | any_on_opt()]) :: any_role()
  def revoke_role!(role, opts \\ []), do: revoke!(role, [{:role, role} | opts])

  @doc """
  Deletes all permissions matching the given DSL options, prefilling `from: subject`.

  Returns `{:ok, subject}` on success, or `{:error, reason}` otherwise.
  """
  @spec revoke_from(any_scope(), [role_opt() | any_on_opt()]) ::
          {:ok, any_scope()} | {:error, term()}
  def revoke_from(subject, opts \\ []), do: revoke(subject, [{:from, subject} | opts])

  @doc """
  Deletes all permissions matching the given DSL options, prefilling `from: subject`.

  Returns `subject` on success, or raises an exception otherwise.
  """
  @spec revoke_from!(any_scope(), [role_opt() | any_on_opt()]) :: any_scope()
  def revoke_from!(subject, opts \\ []), do: revoke!(subject, [{:from, subject} | opts])

  @doc """
  Deletes all permissions matching the given DSL options, prefilling `on: object`.

  Returns `{:ok, object}` on success, or `{:error, reason}` otherwise.
  """
  @spec revoke_on(any_scope(), [role_opt() | any_from_opt()]) ::
          {:ok, any_scope()} | {:error, term()}
  def revoke_on(object, opts \\ []), do: revoke(object, [{:on, object} | opts])

  @doc """
  Deletes all permissions matching the given DSL options, prefilling `on: object`.

  Returns `object` on success, or raises an exception otherwise.
  """
  @spec revoke_on!(any_scope(), [role_opt() | any_from_opt()]) :: any_scope()
  def revoke_on!(object, opts \\ []), do: revoke!(object, [{:on, object} | opts])

  @doc """
  Adds a multi operation to create a role-granting permission from DSL options.

  Returns the updated multi.
  """
  @spec multi_grant(multi(), [role_opt() | to_opt() | on_opt()]) :: multi()
  def multi_grant(%Ecto.Multi{} = multi, opts \\ []), do: apply_to_multi(multi, :grant, opts)

  @doc """
  Adds a multi operation to create a role-granting permission from DSL options, prefilling `role: role`.

  Returns the updated multi.
  """
  @spec multi_grant_role(multi(), role(), [to_opt() | on_opt()]) :: multi()
  def multi_grant_role(%Ecto.Multi{} = multi, role, opts \\ []),
    do: multi_grant(multi, [{:role, role} | opts])

  @doc """
  Adds a multi operation to create a role-granting permission from DSL options, prefilling `to: subject`.

  Returns the updated multi.
  """
  @spec multi_grant_to(multi(), scope(), [role_opt() | on_opt()]) :: multi()
  def multi_grant_to(%Ecto.Multi{} = multi, subject, opts \\ []),
    do: multi_grant(multi, [{:to, subject} | opts])

  @doc """
  Adds a multi operation to create a role-granting permission from DSL options, prefilling `on: object`.

  Returns the updated multi.
  """
  @spec multi_grant_on(multi(), scope(), [role_opt() | to_opt()]) :: multi()
  def multi_grant_on(%Ecto.Multi{} = multi, object, opts \\ []),
    do: multi_grant(multi, [{:on, object} | opts])

  @doc """
  Adds a multi operation to create a role-denying permission from DSL options.

  Returns the updated multi.
  """
  @spec multi_deny(multi(), [role_opt() | to_opt() | on_opt()]) :: multi()
  def multi_deny(%Ecto.Multi{} = multi, opts \\ []), do: apply_to_multi(multi, :deny, opts)

  @doc """
  Adds a multi operation to create a role-denying permission from DSL options, prefilling `role: role`.

  Returns the updated multi.
  """
  @spec multi_deny_role(multi(), role(), [to_opt() | on_opt()]) :: multi()
  def multi_deny_role(%Ecto.Multi{} = multi, role, opts \\ []),
    do: multi_deny(multi, [{:role, role} | opts])

  @doc """
  Adds a multi operation to create a role-denying permission from DSL options, prefilling `to: subject`.

  Returns the updated multi.
  """
  @spec multi_deny_to(multi(), scope(), [role_opt() | on_opt()]) :: multi()
  def multi_deny_to(%Ecto.Multi{} = multi, subject, opts \\ []),
    do: multi_deny(multi, [{:to, subject} | opts])

  @doc """
  Adds a multi operation to create a role-denying permission from DSL options, prefilling `on: object`.

  Returns the updated multi.
  """
  @spec multi_deny_on(multi(), scope(), [role_opt() | to_opt()]) :: multi()
  def multi_deny_on(%Ecto.Multi{} = multi, object, opts \\ []),
    do: multi_deny(multi, [{:on, object} | opts])

  @doc """
  Adds a multi operation to delete all permissions matching the given DSL options.

  Returns the updated multi.
  """
  @spec multi_revoke(multi(), [any_role_opt() | any_from_opt() | any_on_opt()]) :: multi()
  def multi_revoke(%Ecto.Multi{} = multi, opts \\ []), do: apply_to_multi(multi, :revoke, opts)

  @doc """
  Adds a multi operation to delete all permissions matching the given DSL options, prefilling `role: role`.

  Returns the updated multi.
  """
  @spec multi_revoke_role(multi(), any_role(), [any_from_opt() | any_on_opt()]) :: multi()
  def multi_revoke_role(%Ecto.Multi{} = multi, role, opts \\ []),
    do: multi_revoke(multi, [{:role, role} | opts])

  @doc """
  Adds a multi operation to delete all permissions matching the given DSL options, prefilling `from: subject`.

  Returns the updated multi.
  """
  @spec multi_revoke_from(multi(), any_scope(), [any_role_opt() | any_on_opt()]) :: multi()
  def multi_revoke_from(%Ecto.Multi{} = multi, subject, opts \\ []),
    do: multi_revoke(multi, [{:from, subject} | opts])

  @doc """
  Adds a multi operation to delete all permissions matching the given DSL options, prefilling `on: object`.

  Returns the updated multi.
  """
  @spec multi_revoke_on(multi(), any_scope(), [any_role_opt() | any_from_opt()]) :: multi()
  def multi_revoke_on(%Ecto.Multi{} = multi, object, opts \\ []),
    do: multi_revoke(multi, [{:on, object} | opts])

  defp ok(result, return_value) do
    case result do
      :ok -> {:ok, return_value}
      {:ok, _} -> {:ok, return_value}
      _ -> result
    end
  end

  defp ok!(result, return_value \\ :ok) do
    case result do
      :ok -> return_value
      {:ok, _} -> return_value
    end
  end

  defp validate_options(action, opts) do
    case DSL.changeset(action, opts) do
      %{valid?: true} = changeset -> {:ok, changeset}
      changeset -> {:error, changeset}
    end
  end

  # uses apply/3 to execute an action against the configured repo
  defp apply_to_repo(action, opts) do
    with {:ok, {function, args}} <- convert_dsl_to_repo_operation(action, opts) do
      Application.fetch_env!(:rolex, :repo)
      |> apply(function, args)
      |> case do
        {:ok, _permission} -> :ok
        other -> other
      end
    end
  end

  # uses apply/3 to add the indicated action to the multi
  defp apply_to_multi(multi, action, opts) do
    with {:ok, {function, args}} <- convert_dsl_to_repo_operation(action, opts) do
      apply(Ecto.Multi, function, [multi, make_ref() | args])
    end
  end

  # returns {:ok, {function, args}} telling how a repo would execute `action` with DSL `opts`
  defp convert_dsl_to_repo_operation(action, opts) do
    with {:ok, changeset} <- validate_options(action, opts),
         params <- DSL.to_permission_params(changeset) do
      cond do
        action in [:grant, :deny] ->
          {changeset, upsert_options} = Permission.changeset_and_upsert_options(action, params)
          {:ok, {:insert, [changeset, upsert_options]}}

        :revoke ->
          query = Permission.base_query() |> Permission.where_equal(params)
          {:ok, {:delete_all, [query]}}
      end
    end
  end
end
