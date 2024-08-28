defmodule Rolex.PermissionTest do
  use Rolex.DataCase

  alias Rolex.Permission

  def list_roles_where_granted(opts \\ []) do
    Permission.base_query()
    |> Permission.where_granted(opts)
    |> order_by([q], q.role)
    |> select([q], q.role)
    |> Repo.all()
  end

  describe "inspect/2" do
    test "implements the Inspect protocol" do
      assert "%Rolex.Permission<to all on all>" =
               inspect(%Permission{})

      assert "%Rolex.Permission<grant to all :management on all :staff>" =
               inspect(%Permission{verb: :grant, subject_type: :management, object_type: :staff})

      assert "%Rolex.Permission<grant to all Rolex.User on all Rolex.Task>" =
               inspect(%Permission{verb: :grant, subject_type: User, object_type: Task})

      assert "%Rolex.Permission<deny some_role to %Rolex.User{id: 42} on %Rolex.Task{id: 123}>" =
               inspect(%Permission{
                 verb: :deny,
                 role: :some_role,
                 subject_type: User,
                 subject_id: 42,
                 object_type: Task,
                 object_id: 123
               })
    end
  end

  # took this function private to discourage unexpected use
  # describe "parse_options/1" do
  #   test "parses basic options" do
  #     assert %{
  #              verb: :grant,
  #              role: :role_1,
  #              subject_type: @all,
  #              subject_id: @all,
  #              object_type: @all,
  #              object_id: @all
  #            } = Permission.parse_options(verb: :grant, role: :role_1, to: @all, on: @all)
  #   end

  #   test "parses :to_all and :on_all options" do
  #     assert %{
  #              subject_type: User,
  #              subject_id: @all,
  #              object_type: Task,
  #              object_id: @all
  #            } = Permission.parse_options(to_all: User, on_all: Task)
  #   end

  #   test "parses :to_any and :on_any options" do
  #     assert %{
  #              subject_type: User,
  #              subject_id: @any,
  #              object_type: Task,
  #              object_id: @any
  #            } = Permission.parse_options(to_any: User, on_any: Task)
  #   end
  # end

  describe "where_granted/2" do
    setup do
      user = user_fixture()
      task = task_fixture()

      assert {:ok, _} = Rolex.grant_role(:role_1, to: @all, on_all: Task)
      assert {:ok, _} = Rolex.grant_role(:role_2, to_all: User, on: task)
      assert {:ok, _} = Rolex.grant_role(:role_3, to: user, on: @all)

      %{user: user, task: task}
    end

    test "narrows the query to grant permissions not superseded by a deny permission" do
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted()
    end

    test "(on: #{@all}) narrows the query to permissions granted on all resources" do
      assert [:role_3] = list_roles_where_granted(on: @all)
    end

    test "(on_all: _) narrows the query to permissions granted on all resources of the given type" do
      assert [:role_1, :role_3] = list_roles_where_granted(on_all: Task)
      assert [:role_3] = list_roles_where_granted(on_all: User)
    end

    test "(on: @any) narrows the query to permissions granted on anything" do
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted(on: @any)
    end

    test "(on_any: _) narrows the query to permissions granted on any resource of the given type" do
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted(on_any: Task)
      assert [:role_3] = list_roles_where_granted(on_any: User)
    end

    test "(on: _) narrows the query to permissions granted on the given resource",
         %{task: task, user: user} do
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted(on: task)
      assert [:role_3] = list_roles_where_granted(on: user)
    end

    test "(to: #{@all}) narrows the query to permissions granted to all resources" do
      assert [:role_1] = list_roles_where_granted(to: @all)
    end

    test "(to_all: _) narrows the query to permissions granted to all resources of the given type" do
      assert [:role_1] = list_roles_where_granted(to_all: Task)
      assert [:role_1, :role_2] = list_roles_where_granted(to_all: User)
    end

    test "(to: @any) narrows the query to permissions granted to anything" do
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted(to: @any)
    end

    test "(to_any: _)) narrows the query to permissions granted to any resource of the given type" do
      assert [:role_1] = list_roles_where_granted(to_any: Task)
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted(to_any: User)
    end

    test "(to: _) narrows the query to permissions granted to the given resource",
         %{task: task, user: user} do
      assert [:role_1] = list_roles_where_granted(to: task)
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted(to: user)
    end

    test "omits permissions denied at or above the granted scope", %{task: task, user: user} do
      assert {:ok, _} = Rolex.deny_role(:some_other_role, to: user, on: task)
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted(to: user, on: task)

      assert {:ok, _} = Rolex.deny_role(:role_1, to: user, on: task)
      assert [:role_2, :role_3] = list_roles_where_granted(to: user, on: task)

      assert {:ok, _} = Rolex.deny_role(:role_3, to: user, on: @all)
      assert [:role_2] = list_roles_where_granted(to: user, on: task)

      assert {:ok, _} = Rolex.deny_role(:role_2, to: user, on: Task)
      assert [] = list_roles_where_granted(to: user, on: task)
    end
  end
end
