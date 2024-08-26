defmodule Rolex.Control do
  @moduledoc """
  Provides functions for granting, denying, and revoking permissions.
  """

  alias Rolex.Permission

  for verb <- [:grant, :deny] do
    @doc """
    Creates a role-#{verb}ing permission with the given options.

    A permission's subject ("who") and object ("what") define its "scope".
    Subjects and objects may be an entire Ecto schema (e.g. `MyApp.Users.User`),
    a plain atom (e.g. `:users`), or an individual record (e.g. `user`).

    ## Options:

    * `role` - at atom naming the role
    * `to` - the permission subject ("who")
    * `on` - the permission object ("what")

    Returns `{:ok, %Permission{}}` on success.
    """
    def unquote(:"#{verb}")(opts) do
      apply_to_repo(unquote(verb), opts)
    end

    @doc """
    Creates a role-#{verb}ing permission.

    See `c:#{verb}/1` for options.

    Returns `%Permission{}` on success; raises an exception otherwise.
    """
    def unquote(:"#{verb}!")(opts) do
      unquote(:"#{verb}")(opts) |> ok_result!()
    end

    @doc """
    Adds a multi operation to create a role-#{verb}ing permission.

    See `c:#{verb}/1` for options.
    """
    def unquote(:"multi_#{verb}")(multi \\ Ecto.Multi.new(), opts) do
      apply_to_multi(multi, unquote(verb), opts)
    end

    for opt <- [:role, :to, :on] do
      @doc """
      Creates a role-#{verb}ing permission, prefilling `[#{opt}: noun]`.

      See `c:#{verb}/1` for other options.

      Returns `{:ok, noun}` on success.
      """
      def unquote(:"#{verb}_#{opt}")(noun, opts) do
        with {:ok, %Permission{}} <- apply_to_repo(unquote(verb), [{unquote(opt), noun} | opts]) do
          {:ok, noun}
        end
      end

      @doc """
      Creates a role-#{verb}ing permission, prefilling `[#{opt}: noun]`.

      See `c:#{verb}/1` for other options.

      Returns `noun` on success; raises an exception otherwise.
      """
      def unquote(:"#{verb}_#{opt}!")(noun, opts) do
        unquote(:"#{verb}_#{opt}")(noun, opts) |> ok_result!()
      end

      @doc """
      Adds a multi operation to create a role-#{verb}ing permission, prefilling `[#{opt}: noun]`.

      See `c:#{verb}/1` for other options.
      """
      def unquote(:"multi_#{verb}_#{opt}")(multi \\ Ecto.Multi.new(), noun, opts) do
        apply_to_multi(multi, unquote(verb), [{unquote(opt), noun} | opts])
      end
    end
  end

  @doc """
  Deletes all permissions matching the given options exactly.

  ## Options:

  * `role` - at atom naming the role
  * `from` - the permission subject ("who")
  * `on` - the permission object ("what")

  Returns `{:ok, <number-of-permissions-deleted>}` on success.
  """
  def revoke(opts) do
    with {count, _} <- apply_to_repo(:revoke, opts) do
      {:ok, count}
    end
  end

  @doc """
  Deletes all permissions matching the given options exactly.

  Returns the number of permissions deleted on success; raises an exception otherwise.
  """
  def revoke!(opts) do
    revoke(opts) |> ok_result!()
  end

  @doc """
  Adds an operation to delete all permissions matching the given options exactly.
  """
  def multi_revoke(%Ecto.Multi{} = multi \\ Ecto.Multi.new(), opts) do
    apply_to_multi(multi, :revoke, opts)
  end

  for opt <- [:role, :from, :on] do
    @doc """
    Deletes all permissions matching the given options exactly, prefilling `[#{opt}: noun]`.

    See `c:revoke/1` for other options.

    Returns `{:ok, <number-of-permissions-deleted>}` on success.
    """
    def unquote(:"revoke_#{opt}")(noun, opts) do
      revoke([{unquote(opt), noun} | opts])
    end

    @doc """
    Deletes all permissions matching the given options exactly, prefilling `[#{opt}: noun]`.

    See `c:revoke/1` for other options.

    Returns the number of permissions deleted on success; raises an exception otherwise.
    """
    def unquote(:"revoke_#{opt}!")(noun, opts) do
      revoke([{unquote(opt), noun} | opts]) |> ok_result!()
    end

    @doc """
    Adds a multi operation to delete all permissions matching the given options exactly, prefilling `[#{opt}: noun]`.

    See `c:revoke/1` for other options.
    """
    def unquote(:"multi_revoke_#{opt}")(multi \\ Ecto.Multi.new(), noun, opts) do
      multi_revoke(multi, [{unquote(opt), noun} | opts])
    end
  end

  defp ok_result!({:ok, result}), do: result

  # uses apply/3 to execute an operation against the configured repo
  defp apply_to_repo(operation, opts) do
    {function, args} = operation_tuple(operation, opts)

    Application.fetch_env!(:rolex, :repo)
    |> apply(function, args)
  end

  # uses apply/3 to add the indicated operation to the multi
  defp apply_to_multi(multi, operation, opts) do
    {function, args} = operation_tuple(operation, opts)
    apply(Ecto.Multi, function, [multi, make_ref() | args])
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
    opts = Keyword.delete(opts, :verb)
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
