defmodule Rolex.PermissionTest do
  use Rolex.DataCase

  import Rolex.Permission

  alias Rolex.Permission

  def list_roles_where_granted(opts \\ []) do
    base_query()
    |> where_granted(opts)
    |> order_by([q], q.role)
    |> select([q], q.role)
    |> Repo.all()
  end

  describe "inspect/2" do
    test "implements the Inspect protocol" do
      assert "%Rolex.Permission<>" = inspect(%Permission{})

      assert "%Rolex.Permission<grant to all Rolex.User on all Rolex.Task>" =
               inspect(%Permission{
                 verb: :grant,
                 subject_type: User,
                 subject_id: :all,
                 object_type: Task,
                 object_id: :all
               })

      assert "%Rolex.Permission<deny some_role to Rolex.User 42 on Rolex.Task 123>" =
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

  describe "where_granted/2" do
    setup do
      user = user_fixture()
      task = task_fixture()

      assert struct(Permission,
               verb: :grant,
               role: :role_1,
               subject_type: @all,
               subject_id: @all,
               object_type: Task,
               object_id: @all
             )
             |> Repo.insert!()

      assert struct(Permission,
               verb: :grant,
               role: :role_2,
               subject_type: User,
               subject_id: @all,
               object_type: Task,
               object_id: task.id
             )
             |> Repo.insert!()

      assert struct(Permission,
               verb: :grant,
               role: :role_3,
               subject_type: User,
               subject_id: user.id,
               object_type: @all,
               object_id: @all
             )
             |> Repo.insert!()

      %{user: user, task: task}
    end

    test "narrows the query to grant permissions not superseded by a deny permission" do
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted()
    end

    test "(on: #{@all}) narrows the query to permissions granted on all resources" do
      assert [:role_3] = list_roles_where_granted(object_type: @all, object_id: @all)
    end

    test "(on: <schema>) narrows the query to permissions granted on all resources of the given type" do
      assert [:role_1, :role_3] = list_roles_where_granted(object_type: Task, object_id: @all)
      assert [:role_3] = list_roles_where_granted(object_type: User, object_id: @all)
    end

    test "(on: #{@any}) narrows the query to permissions granted on anything" do
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted()
    end

    test "(on: {:any, <schema>}) narrows the query to permissions granted on any resource of the given type" do
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted(object_type: Task)
      assert [:role_3] = list_roles_where_granted(object_type: User)
    end

    test "(on: _) narrows the query to permissions granted on the given resource",
         %{task: task, user: user} do
      assert [:role_1, :role_2, :role_3] =
               list_roles_where_granted(object_type: Task, object_id: task.id)

      assert [:role_3] = list_roles_where_granted(object_type: User, object_id: user.id)
    end

    test "(to: #{@all}) narrows the query to permissions granted to all resources" do
      assert [:role_1] = list_roles_where_granted(subject_type: @all, subject_id: @all)
    end

    test "(to: <schema>) narrows the query to permissions granted to all resources of the given type" do
      assert [:role_1] = list_roles_where_granted(subject_type: Task, subject_id: @all)
      assert [:role_1, :role_2] = list_roles_where_granted(subject_type: User, subject_id: @all)
    end

    test "(to: #{@any}) narrows the query to permissions granted to anything" do
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted()
    end

    test "(to: {:any, <schema>})) narrows the query to permissions granted to any resource of the given type" do
      assert [:role_1] = list_roles_where_granted(subject_type: Task)
      assert [:role_1, :role_2, :role_3] = list_roles_where_granted(subject_type: User)
    end

    test "(to: _) narrows the query to permissions granted to the given resource",
         %{task: task, user: user} do
      assert [:role_1] = list_roles_where_granted(subject_type: Task, subject_id: task.id)

      assert [:role_1, :role_2, :role_3] =
               list_roles_where_granted(subject_type: User, subject_id: user.id)
    end

    # test "omits permissions denied at or above the granted scope", %{task: task, user: user} do
    #   assert struct(Permission, role: :some_other_role, to: user, on: task) |> Repo.insert!()
    #   assert [:role_1, :role_2, :role_3] = list_roles_where_granted(to: user, on: task)

    #   assert struct(Permission, role: :role_1, to: user, on: task) |> Repo.insert!()
    #   assert [:role_2, :role_3] = list_roles_where_granted(to: user, on: task)

    #   assert struct(Permission, role: :role_3, to: user, on: @all) |> Repo.insert!()
    #   assert [:role_2] = list_roles_where_granted(to: user, on: task)

    #   assert struct(Permission, role: :role_2, to: user, on: Task) |> Repo.insert!()
    #   assert [] = list_roles_where_granted(to: user, on: task)
    # end
  end
end
