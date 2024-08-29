defmodule Rolex do
  @moduledoc """
  Documentation for `Rolex`.
  """

  alias Rolex.Control
  alias Rolex.Permission
  alias Rolex.Queryable

  # Loading

  @doc """
  Returns true if any of the given permissions meeting the conditions in `opts` are granted.
  """
  def granted?(permissions, opts) do
    permissions |> Permission.filter_granted(opts) |> Enum.any?()
  end

  @doc """
  Returns true if any of the given permissions meeting the conditions in `opts` are granted.
  """
  for opt <- [:role, :to, :on] do
    def unquote(:"granted_#{opt}?")(permissions, noun, opts \\ []) do
      granted?(permissions, [{unquote(opt), noun} | opts])
    end
  end

  @doc """
  Fetches from the database a list of all permissions granted to `subject`.

  This list can subsequently be used for in-memory permission checks by e.g. `granted_role?/3`.
  """
  def load_permissions_granted_to(subject) do
    repo = Application.fetch_env!(:rolex, :repo)

    Permission.base_query()
    |> Permission.where_granted(to: subject)
    |> repo.all()
  end

  # Querying and filtering

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
