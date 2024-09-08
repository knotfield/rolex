defmodule Rolex do
  @moduledoc """
  The main entry point for interacting with Rolex.
  """

  alias Rolex.Check
  alias Rolex.Control
  alias Rolex.DSL
  alias Rolex.Permission
  alias Rolex.Queryable

  # Loading

  @doc """
  Fetches from the database a list of all permissions granted to `subject`.

  This list can subsequently be used for in-memory permission checks by e.g. `granted_role?/3`.
  """
  def load_permissions_granted_to(subject) do
    repo = Application.fetch_env!(:rolex, :repo)

    params =
      DSL.changeset_for_filter(to: subject)
      |> DSL.to_permission_params()

    Permission.base_query()
    |> Permission.where_granted(params)
    |> repo.all()
  end

  # Role checks

  defdelegate granted?(permissions, opts \\ []), to: Check
  defdelegate granted_role?(permissions, role, opts \\ []), to: Check
  defdelegate granted_to?(permissions, subject, opts \\ []), to: Check
  defdelegate granted_on?(permissions, object, opts \\ []), to: Check

  # Queryable
  # Scoping subject and object queries
  # Preloading permissions onto subjects and objects

  defdelegate preload_permissions(ids, assoc), to: Queryable
  defdelegate where_granted_to(query, opts \\ []), to: Queryable
  defdelegate where_granted_on(query, opts \\ []), to: Queryable

  # Granting, denying, and revoking

  defdelegate grant(opts \\ []), to: Control
  defdelegate grant!(opts \\ []), to: Control
  defdelegate grant_role(role, opts \\ []), to: Control
  defdelegate grant_role!(role, opts \\ []), to: Control
  defdelegate grant_to(subject, opts \\ []), to: Control
  defdelegate grant_to!(subject, opts \\ []), to: Control
  defdelegate grant_on(object, opts \\ []), to: Control
  defdelegate grant_on!(object, opts \\ []), to: Control
  defdelegate deny(opts \\ []), to: Control
  defdelegate deny!(opts \\ []), to: Control
  defdelegate deny_role(role, opts \\ []), to: Control
  defdelegate deny_role!(role, opts \\ []), to: Control
  defdelegate deny_to(subject, opts \\ []), to: Control
  defdelegate deny_to!(subject, opts \\ []), to: Control
  defdelegate deny_on(object, opts \\ []), to: Control
  defdelegate deny_on!(object, opts \\ []), to: Control
  defdelegate revoke(opts \\ []), to: Control
  defdelegate revoke!(opts \\ []), to: Control
  defdelegate revoke_role(role, opts \\ []), to: Control
  defdelegate revoke_role!(role, opts \\ []), to: Control
  defdelegate revoke_from(subject, opts \\ []), to: Control
  defdelegate revoke_from!(subject, opts \\ []), to: Control
  defdelegate revoke_on(object, opts \\ []), to: Control
  defdelegate revoke_on!(object, opts \\ []), to: Control

  defdelegate multi_grant(multi, opts \\ []), to: Control
  defdelegate multi_grant_role(multi, role, opts \\ []), to: Control
  defdelegate multi_grant_to(multi, subject, opts \\ []), to: Control
  defdelegate multi_grant_on(multi, object, opts \\ []), to: Control
  defdelegate multi_deny(multi, opts \\ []), to: Control
  defdelegate multi_deny_role(multi, role, opts \\ []), to: Control
  defdelegate multi_deny_to(multi, subject, opts \\ []), to: Control
  defdelegate multi_deny_on(multi, object, opts \\ []), to: Control
  defdelegate multi_revoke(multi, opts \\ []), to: Control
  defdelegate multi_revoke_role(multi, role, opts \\ []), to: Control
  defdelegate multi_revoke_from(multi, subject, opts \\ []), to: Control
  defdelegate multi_revoke_on(multi, object, opts \\ []), to: Control
end
