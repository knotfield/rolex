defmodule RolexTest do
  use Rolex.DataCase

  doctest Rolex

  setup do
    user = user_fixture()
    task = task_fixture()

    assert {:ok, _} = Rolex.grant_role(:role_1, to: @all, on: Task)
    assert {:ok, _} = Rolex.grant_role(:role_2, to: User, on: task)
    assert {:ok, _} = Rolex.grant_role(:role_3, to: user, on: @all)

    permissions = Rolex.load_permissions_granted_to(user)

    %{user: user, task: task, permissions: permissions}
  end

  describe "granted?/2" do
    test "returns true if the permission list meets conditions",
         %{task: task, permissions: permissions} do
      assert permissions |> Rolex.granted?(role: :role_1, on: task)
      assert permissions |> Rolex.granted?(role: :role_2, on: task)
      assert permissions |> Rolex.granted?(role: :role_3, on: task)

      other_task = task_fixture()
      assert permissions |> Rolex.granted?(role: :role_1, on: other_task)
      refute permissions |> Rolex.granted?(role: :role_2, on: other_task)
      assert permissions |> Rolex.granted?(role: :role_3, on: other_task)

      other_user = user_fixture()
      refute permissions |> Rolex.granted?(role: :role_1, on: other_user)
      refute permissions |> Rolex.granted?(role: :role_2, on: other_user)
      assert permissions |> Rolex.granted?(role: :role_3, on: other_user)
    end
  end

  describe "granted_role?/2" do
    test "returns true if the permission list grants the specified role",
         %{task: task, permissions: permissions} do
      assert permissions |> Rolex.granted_role?(:role_1, on: task)
      assert permissions |> Rolex.granted_role?(:role_2, on: task)
      assert permissions |> Rolex.granted_role?(:role_3, on: task)

      other_task = task_fixture()
      assert permissions |> Rolex.granted_role?(:role_1, on: other_task)
      refute permissions |> Rolex.granted_role?(:role_2, on: other_task)
      assert permissions |> Rolex.granted_role?(:role_3, on: other_task)

      other_user = user_fixture()
      refute permissions |> Rolex.granted_role?(:role_1, on: other_user)
      refute permissions |> Rolex.granted_role?(:role_2, on: other_user)
      assert permissions |> Rolex.granted_role?(:role_3, on: other_user)
    end
  end
end
