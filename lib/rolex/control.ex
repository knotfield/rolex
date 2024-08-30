defmodule Rolex.Control do
  @moduledoc """
  Provides functions for granting, denying, and revoking permissions.
  """

  alias Rolex.DSL
  alias Rolex.Permission

  for verb <- [:grant, :deny] do
    @doc """
    Creates a role-#{verb}ing `m:Rolex.Permission` from DSL options.

    Returns `{:ok, permission}` on success, or `{:error, reason}` otherwise.

    See `m:Rolex.DSL` for options.
    """
    def unquote(:"#{verb}")(opts \\ []) do
      apply_to_repo(unquote(verb), opts)
    end

    @doc """
    Creates a role-#{verb}ing `m:Rolex.Permission` from DSL options.

    Returns the permission on success, or raises an exception otherwise.

    See `m:Rolex.DSL` for options.
    """
    def unquote(:"#{verb}!")(opts \\ []) do
      unquote(:"#{verb}")(opts) |> ok_result!()
    end

    @doc """
    Adds a multi operation to create a role-#{verb}ing `m:Rolex.Permission`.

    Returns the updated multi.

    See `m:Rolex.DSL` for options.
    """
    def unquote(:"multi_#{verb}")(%Ecto.Multi{} = multi, opts \\ []) do
      apply_to_multi(multi, unquote(verb), opts)
    end

    for {opt, varname} <- [role: :role, to: :subject_scope, on: :object_scope] do
      @doc """
      Creates a role-#{verb}ing `m:Rolex.Permission` from DSL options, prefilling `#{opt}: #{varname}`.

      Returns `{:ok, #{varname}}` on success.

      See `m:Rolex.DSL` for other options.
      """
      def unquote(:"#{verb}_#{opt}")(unquote(Macro.var(varname, nil)), opts \\ []) do
        with {:ok, %Permission{}} <-
               apply_to_repo(unquote(verb), [
                 {unquote(opt), unquote(Macro.var(varname, nil))} | opts
               ]) do
          {:ok, unquote(Macro.var(varname, nil))}
        end
      end

      @doc """
      Creates a role-#{verb}ing `m:Rolex.Permission` from DSL options, prefilling `#{opt}: #{varname}`.

      Returns `#{varname}` on success, or raises an exception otherwise.

      See `m:Rolex.DSL` for other options.
      """
      def unquote(:"#{verb}_#{opt}!")(unquote(Macro.var(varname, nil)), opts \\ []) do
        unquote(:"#{verb}_#{opt}")(unquote(Macro.var(varname, nil)), opts) |> ok_result!()
      end

      @doc """
      Adds a multi operation to create a role-#{verb}ing `m:Rolex.Permission` from DSL options, prefilling `#{opt}: #{varname}`.

      Returns the updated multi.

      See `m:Rolex.DSL` for other options.
      """
      def unquote(:"multi_#{verb}_#{opt}")(
            %Ecto.Multi{} = multi,
            unquote(Macro.var(varname, nil)),
            opts \\ []
          ) do
        apply_to_multi(multi, unquote(verb), [
          {unquote(opt), unquote(Macro.var(varname, nil))} | opts
        ])
      end
    end
  end

  @doc """
  Deletes all `m:Rolex.Permission`s matching the given DSL options.

  Returns `{:ok, <number-of-permissions-deleted>}` on success, or {:error, changeset} otherwise.

  See `m:Rolex.DSL` for options.
  """
  def revoke(opts \\ []) do
    with {count, _} when is_integer(count) <- apply_to_repo(:revoke, opts) do
      {:ok, count}
    end
  end

  @doc """
  Deletes all `m:Rolex.Permission`s matching the given DSL options.

  Returns the number of permissions deleted on success, or raises an exception otherwise.

  See `m:Rolex.DSL` for options.
  """
  def revoke!(opts) do
    revoke(opts) |> ok_result!()
  end

  @doc """
  Adds an operation to delete all `m:Rolex.Permission`s matching the given DSL options.

  Returns the updated multi.

  See `m:Rolex.DSL` for options.
  """
  def multi_revoke(%Ecto.Multi{} = multi, opts) do
    apply_to_multi(multi, :revoke, opts)
  end

  for {opt, varname} <- [role: :role, from: :subject_scope, on: :object_scope] do
    @doc """
    Deletes all `m:Rolex.Permission`s matching the given DSL options, prefilling `#{opt}: #{varname}`.

    Returns `{:ok, #{varname}}` on success.

    See `m:Rolex.DSL` for other options.
    """
    def unquote(:"revoke_#{opt}")(unquote(Macro.var(varname, nil)), opts \\ []) do
      with {:ok, _} <- revoke([{unquote(opt), unquote(Macro.var(varname, nil))} | opts]) do
        {:ok, unquote(Macro.var(varname, nil))}
      end
    end

    @doc """
    Deletes all `m:Rolex.Permission`s matching the given DSL options, prefilling `#{opt}: #{varname}`.

    Returns the number of permissions deleted on success, or raises an exception otherwise.

    See `m:Rolex.DSL` for other options.
    """
    def unquote(:"revoke_#{opt}!")(unquote(Macro.var(varname, nil)), opts \\ []) do
      revoke([{unquote(opt), unquote(Macro.var(varname, nil))} | opts]) |> ok_result!()
    end

    @doc """
    Adds a multi operation to delete all `m:Rolex.Permission`s matching the given DSL options, prefilling `#{opt}: #{varname}`.

    Returns the updated multi.

    See `m:Rolex.DSL` for other options.
    """
    def unquote(:"multi_revoke_#{opt}")(
          %Ecto.Multi{} = multi,
          unquote(Macro.var(varname, nil)),
          opts \\ []
        ) do
      multi_revoke(multi, [{unquote(opt), unquote(Macro.var(varname, nil))} | opts])
    end
  end

  defp ok_result!({:ok, result}), do: result

  defp validate_options(operation, opts) do
    case DSL.changeset(operation, opts) do
      %{valid?: true} = changeset -> {:ok, changeset}
      changeset -> {:error, changeset}
    end
  end

  # uses apply/3 to execute an operation against the configured repo
  defp apply_to_repo(operation, opts) do
    with {:ok, changeset} <- validate_options(operation, opts),
         params <- DSL.to_permission_params(changeset) do
      {function, args} = operation_tuple(operation, params)

      Application.fetch_env!(:rolex, :repo)
      |> apply(function, args)
    end
  end

  # uses apply/3 to add the indicated operation to the multi
  defp apply_to_multi(multi, operation, opts) do
    with {:ok, changeset} <- validate_options(operation, opts),
         params <- DSL.to_permission_params(changeset) do
      {function, args} = operation_tuple(operation, params)
      apply(Ecto.Multi, function, [multi, make_ref() | args])
    end
  end

  # returns a {function, args} tuple that can be used with either a repo or a multi
  defp operation_tuple(:grant, opts) do
    Permission.grant_changeset(opts)
    |> changeset_upsert_tuple()
  end

  defp operation_tuple(:deny, opts) do
    Permission.deny_changeset(opts)
    |> changeset_upsert_tuple()
  end

  defp operation_tuple(:revoke, opts) do
    query = Permission.base_query() |> Permission.where_equal(opts)
    {:delete_all, [query]}
  end

  defp changeset_upsert_tuple(changeset) do
    {
      :insert,
      [
        changeset,
        [
          on_conflict: [set: [verb: changeset.data.verb]],
          conflict_target: ~w(verb role subject_type subject_id object_type object_id)a,
          returning: true
        ]
      ]
    }
  end
end
