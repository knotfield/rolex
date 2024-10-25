defmodule Rolex.QueryableTest do
  use Rolex.DataCase

  import Rolex.Queryable

  alias Rolex.DSL

  defp list_users_granted_to(opts) do
    from(q in User)
    |> where_granted_to(opts)
    |> order_by([q], q.id)
    |> Repo.all()
  end

  defp list_tasks_granted_on(opts) do
    from(q in Task)
    |> where_granted_on(opts)
    |> order_by([q], q.id)
    |> Repo.all()
  end

  setup do
    [user_1, user_2] = user_fixtures(2)
    [task_1, task_2] = task_fixtures(2)

    Rolex.grant_role!(:role_1, to: @all, on: Task)
    Rolex.grant_role!(:role_2, to: User, on: task_1)
    Rolex.grant_role!(:role_3, to: user_1, on: @all)

    %{user_1: user_1, user_2: user_2, task_1: task_1, task_2: task_2}
  end

  describe "preload_permissions/3" do
    test "preloads permissions on a query" do
      assert [user_1, user_2] =
               from(u in User, order_by: u.id)
               |> preload_permissions(:permissions)
               |> Repo.all()

      assert [:role_1, :role_2, :role_3] ==
               user_1.permissions |> Enum.map(& &1.role) |> Enum.uniq() |> Enum.sort()

      assert [:role_1, :role_2] ==
               user_2.permissions |> Enum.map(& &1.role) |> Enum.uniq() |> Enum.sort()
    end

    test "preloads permissions on individual records", %{user_1: user_1, user_2: user_2} do
      [user_1, user_2] = [user_1, user_2] |> preload_permissions(:permissions, force: true)

      assert [:role_1, :role_2, :role_3] ==
               user_1.permissions |> Enum.map(& &1.role) |> Enum.uniq() |> Enum.sort()

      assert [:role_1, :role_2] ==
               user_2.permissions |> Enum.map(& &1.role) |> Enum.uniq() |> Enum.sort()
    end
  end

  describe "where_granted_to/2" do
    test "[on: @any] narrows query to subjects where role was granted, period",
         %{user_1: user_1, user_2: user_2} do
      assert [^user_1, ^user_2] = list_users_granted_to(role: :role_1, on: @any)
      assert [^user_1, ^user_2] = list_users_granted_to(role: :role_2, on: @any)
      assert [^user_1] = list_users_granted_to(role: :role_3, on: @any)
    end

    test "[on: object] narrows query to subjects where role was granted on object",
         %{user_1: user_1, user_2: user_2, task_1: task_1, task_2: task_2} do
      assert [^user_1, ^user_2] = list_users_granted_to(role: :role_1, on: task_1)
      assert [^user_1, ^user_2] = list_users_granted_to(role: :role_2, on: task_1)
      assert [^user_1] = list_users_granted_to(role: :role_3, on: task_1)

      assert [^user_1, ^user_2] = list_users_granted_to(role: :role_1, on: task_2)
      assert [] = list_users_granted_to(role: :role_2, on: task_2)
      assert [^user_1] = list_users_granted_to(role: :role_3, on: task_2)
    end

    test "[to: subject] narrows query to objects where role was granted to subject",
         %{user_1: user_1, user_2: user_2, task_1: task_1, task_2: task_2} do
      assert [^task_1, ^task_2] = list_tasks_granted_on(role: :role_1, to: user_1)
      assert [^task_1] = list_tasks_granted_on(role: :role_2, to: user_1)
      assert [^task_1, ^task_2] = list_tasks_granted_on(role: :role_3, to: user_1)

      assert [^task_1, ^task_2] = list_tasks_granted_on(role: :role_1, to: user_2)
      assert [^task_1] = list_tasks_granted_on(role: :role_2, to: user_2)
      assert [] = list_tasks_granted_on(role: :role_3, to: user_2)
    end

    test "[role: <list>] narrows query to objects where any of the listed roles were granted to subject",
         %{user_1: user_1, user_2: user_2} do
      assert [^user_1, ^user_2] = list_users_granted_to(role: [:role_1, :role_2], on: @any)
      assert [^user_1] = list_users_granted_to(role: [:role_3], on: @any)
    end

    test "returns each object only once", %{task_1: task_1, user_1: user_1} do
      user_1
      |> Rolex.grant_to!(role: :even, on: :all)
      |> Rolex.grant_to!(role: :more, on: Task)
      |> Rolex.grant_to!(role: :roles, on: task_1)

      task_1
      |> Rolex.grant_on!(role: :this, to: :all)
      |> Rolex.grant_on!(role: :may_be, to: User)
      |> Rolex.grant_on!(role: :excessive, to: user_1)

      assert [^task_1] =
               list_tasks_granted_on(to: user_1)
               |> Enum.filter(&(&1.id == task_1.id))

      assert [^user_1] =
               list_users_granted_to(on: task_1)
               |> Enum.filter(&(&1.id == user_1.id))
    end
  end

  # gets granted roles both ways and returns them if they match -- or raises if they don't
  defp list_roles_granted(opts \\ []) do
    params =
      DSL.changeset_for_filter(opts)
      |> DSL.to_permission_params()

    selected =
      Permission.base_query()
      |> Permission.where_granted(params)
      |> select([p], p.role)
      |> order_by([p], p.role)
      |> Repo.all()

    filtered =
      Permission.base_query()
      |> Repo.all()
      |> Permission.filter_granted(params)
      |> Enum.map(& &1.role)
      |> Enum.sort()

    ^filtered = selected
  end

  # we test these together because it's vital that they return the same results
  describe "where_granted/2 and filter_granted/2" do
    test "filters the list to grant permissions not superseded by a deny permission" do
      assert [:role_1, :role_2, :role_3] = list_roles_granted()
    end

    test "[on: #{@all}] filters the list to permissions granted on all resources" do
      assert [:role_3] = list_roles_granted(on: @all)
    end

    test "[on: <schema>] filters the list to permissions granted on all resources of the given type" do
      assert [:role_1, :role_3] = list_roles_granted(on: Task)
      assert [:role_3] = list_roles_granted(on: User)
    end

    test "[on: #{inspect(@any)}] filters the list to permissions granted on anything" do
      assert [:role_1, :role_2, :role_3] = list_roles_granted(on: @any)
    end

    test "[on: {#{inspect(@any)}, <schema>}] filters the list to permissions granted on any resource of the given type" do
      assert [:role_1, :role_2, :role_3] = list_roles_granted(on: {:any, Task})
      assert [:role_3] = list_roles_granted(on: {:any, User})
    end

    test "[on: _] filters the list to permissions granted on the given resource",
         %{task_1: task_1, user_1: user_1} do
      assert [:role_1, :role_2, :role_3] = list_roles_granted(on: task_1)
      assert [:role_3] = list_roles_granted(on: user_1)
    end

    test "[to: #{@all}] filters the list to permissions granted to all resources" do
      assert [:role_1] = list_roles_granted(to: @all)
    end

    test "[to: <schema>] filters the list to permissions granted to all resources of the given type" do
      assert [:role_1] = list_roles_granted(to: Task)
      assert [:role_1, :role_2] = list_roles_granted(to: User)
    end

    test "[to: #{inspect(@any)}] filters the list to permissions granted to anything" do
      assert [:role_1, :role_2, :role_3] = list_roles_granted(to: @any)
    end

    test "[to: {#{inspect(@any)}, <schema>}] filters the list to permissions granted to any resource of the given type" do
      assert [:role_1] = list_roles_granted(to: {:any, Task})
      assert [:role_1, :role_2, :role_3] = list_roles_granted(to: {:any, User})
    end

    test "[to: _] filters the list to permissions granted to the given resource",
         %{task_1: task_1, user_1: user_1} do
      assert [:role_1] = list_roles_granted(to: task_1)
      assert [:role_1, :role_2, :role_3] = list_roles_granted(to: user_1)
    end

    test "[role: <list>] filters the list to permissions granting any of the listed roles",
         %{task_1: task_1, user_1: user_1} do
      assert [] = list_roles_granted(to: task_1, role: [:role_2, :role_3])
      assert [:role_2, :role_3] = list_roles_granted(to: user_1, role: [:role_2, :role_3])
    end

    test "omits permissions denied at or above the granted scope",
         %{task_1: task_1, user_1: user_1} do
      Rolex.deny_role!(:some_other_role, to: user_1, on: task_1)
      assert [:role_1, :role_2, :role_3] = list_roles_granted(to: user_1, on: task_1)

      Rolex.deny_role!(:role_1, to: user_1, on: task_1)
      assert [:role_2, :role_3] = list_roles_granted(to: user_1, on: task_1)

      Rolex.deny_role!(:role_3, to: user_1, on: @all)
      assert [:role_2] = list_roles_granted(to: user_1, on: task_1)

      Rolex.deny_role!(:role_2, to: user_1, on: Task)
      assert [] = list_roles_granted(to: user_1, on: task_1)
    end
  end
end
