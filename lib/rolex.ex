defmodule Rolex do
  @moduledoc """
  Documentation for `Rolex`.
  """

  alias Rolex.Control
  alias Rolex.Permission
  alias Rolex.Queryable

  # Loading

  def granted?(permissions, opts) do
    permissions |> Permission.filter_granted(opts) |> Enum.any?()
  end

  for opt <- [:role, :to, :on] do
    def unquote(:"granted_#{opt}?")(permissions, noun, opts \\ []) do
      granted?(permissions, [{unquote(opt), noun} | opts])
    end
  end

  def load_permissions_granted_to(subject) do
    repo = Application.fetch_env!(:rolex, :repo)

    Permission.base_query()
    |> Permission.where_granted(to: subject)
    |> repo.all()
  end

  defdelegate list_roles_granted_to(list, subject, opts \\ []), to: Queryable
  defdelegate list_roles_granted_on(list, object, opts \\ []), to: Queryable

  # Querying and filtering

  defdelegate where_granted_to(query, opts \\ []), to: Queryable
  defdelegate where_granted_on(query, opts \\ []), to: Queryable

  # Granting, denying, and revoking

  @new_multi Ecto.Multi.new()

  defdelegate grant(opts), to: Control
  defdelegate grant!(opts), to: Control
  defdelegate grant_role(role, opts), to: Control
  defdelegate grant_role!(role, opts), to: Control
  defdelegate grant_to(subject, opts), to: Control
  defdelegate grant_to!(subject, opts), to: Control
  defdelegate grant_on(object, opts), to: Control
  defdelegate grant_on!(object, opts), to: Control
  defdelegate deny(opts), to: Control
  defdelegate deny!(opts), to: Control
  defdelegate deny_role(role, opts), to: Control
  defdelegate deny_role!(role, opts), to: Control
  defdelegate deny_to(subject, opts), to: Control
  defdelegate deny_to!(subject, opts), to: Control
  defdelegate deny_on(object, opts), to: Control
  defdelegate deny_on!(object, opts), to: Control
  defdelegate revoke(opts), to: Control
  defdelegate revoke!(opts), to: Control
  defdelegate revoke_role(role, opts), to: Control
  defdelegate revoke_role!(role, opts), to: Control
  defdelegate revoke_from(subject, opts), to: Control
  defdelegate revoke_from!(subject, opts), to: Control
  defdelegate revoke_on(object, opts), to: Control
  defdelegate revoke_on!(object, opts), to: Control

  defdelegate multi_grant(multi \\ @new_multi, opts), to: Control
  defdelegate multi_grant_role(multi \\ @new_multi, opts), to: Control
  defdelegate multi_grant_to(multi \\ @new_multi, opts), to: Control
  defdelegate multi_grant_on(multi \\ @new_multi, opts), to: Control
  defdelegate multi_deny(multi \\ @new_multi, opts), to: Control
  defdelegate multi_deny_role(multi \\ @new_multi, opts), to: Control
  defdelegate multi_deny_to(multi \\ @new_multi, opts), to: Control
  defdelegate multi_deny_on(multi \\ @new_multi, opts), to: Control
  defdelegate multi_revoke(multi \\ @new_multi, opts), to: Control
  defdelegate multi_revoke_role(multi \\ @new_multi, opts), to: Control
  defdelegate multi_revoke_from(multi \\ @new_multi, opts), to: Control
  defdelegate multi_revoke_on(multi \\ @new_multi, opts), to: Control
end
