defmodule Rolex.CheckTest do
  use Rolex.DataCase

  import Rolex.Check

  setup do
    user = user_fixture()
    task = task_fixture()

    Rolex.grant_role!(:role_1, to: @all, on: Task)
    Rolex.grant_role!(:role_2, to: User, on: task)
    Rolex.grant_role!(:role_3, to: user, on: @all)
    Rolex.grant_role!(:role_4, to: @all, on: @all)
    Rolex.deny_role!(:role_4, to: @all, on: @all)

    permissions = Permission |> Rolex.Repo.all()

    %{user: user, task: task, permissions: permissions}
  end

  describe "roles_granted/2" do
    test "lists roles granted by a list of permissions",
         %{task: task, permissions: permissions, user: user} do
      assert [:role_1, :role_2, :role_3] = permissions |> roles_granted()
      assert [:role_1, :role_2, :role_3] = permissions |> roles_granted(to: user)
      assert [:role_1, :role_2, :role_3] = permissions |> roles_granted(on: task)
      assert [:role_1, :role_2, :role_3] = permissions |> roles_granted(to: user, on: task)

      other_user = user_fixture()
      assert [:role_1, :role_2] = permissions |> roles_granted(to: other_user)
      assert [:role_1, :role_2] = permissions |> roles_granted(to: other_user, on: task)

      other_task = task_fixture()
      assert [:role_1, :role_3] = permissions |> roles_granted(on: other_task)
      assert [:role_1, :role_3] = permissions |> roles_granted(on: other_task, to: user)
    end
  end

  describe "roles_granted_to/2" do
    test "lists roles granted by a list of permissions",
         %{task: task, permissions: permissions, user: user} do
      assert [:role_1, :role_2, :role_3] = permissions |> roles_granted_to(user)
      assert [:role_1, :role_2, :role_3] = permissions |> roles_granted_to(user, on: task)
      assert [:role_1] = permissions |> roles_granted_to(task)
      assert [] = permissions |> roles_granted_to(task, on: user)

      other_user = user_fixture()
      assert [:role_1, :role_2] = permissions |> roles_granted_to(other_user)
      assert [:role_1, :role_2] = permissions |> roles_granted_to(other_user, on: task)
    end
  end

  describe "roles_granted_on/2" do
    test "lists roles granted by a list of permissions",
         %{task: task, permissions: permissions, user: user} do
      assert [:role_3] = permissions |> roles_granted_on(user)
      assert [:role_1, :role_2, :role_3] = permissions |> roles_granted_on(task)
      assert [:role_1, :role_2, :role_3] = permissions |> roles_granted_on(task, to: user)

      other_task = task_fixture()
      assert [:role_1, :role_3] = permissions |> roles_granted_on(other_task)
      assert [:role_1, :role_3] = permissions |> roles_granted_on(other_task, to: user)
      assert [:role_1] = permissions |> roles_granted_on(other_task, to: user_fixture())
    end
  end

  describe "granted?/2" do
    test "returns true if the permission list meets conditions",
         %{task: task, permissions: permissions} do
      assert permissions |> granted?(role: :role_1, on: task)
      assert permissions |> granted?(role: :role_2, on: task)
      assert permissions |> granted?(role: :role_3, on: task)

      other_task = task_fixture()
      assert permissions |> granted?(role: :role_1, on: other_task)
      refute permissions |> granted?(role: :role_2, on: other_task)
      assert permissions |> granted?(role: :role_3, on: other_task)

      other_user = user_fixture()
      refute permissions |> granted?(role: :role_1, on: other_user)
      refute permissions |> granted?(role: :role_2, on: other_user)
      assert permissions |> granted?(role: :role_3, on: other_user)
    end
  end

  describe "granted_role?/3" do
    test "returns true if the permission list meets conditions",
         %{task: task, permissions: permissions} do
      assert permissions |> granted_role?(:role_1, on: task)
      assert permissions |> granted_role?(:role_2, on: task)
      assert permissions |> granted_role?(:role_3, on: task)

      other_task = task_fixture()
      assert permissions |> granted_role?(:role_1, on: other_task)
      refute permissions |> granted_role?(:role_2, on: other_task)
      assert permissions |> granted_role?(:role_3, on: other_task)

      other_user = user_fixture()
      refute permissions |> granted_role?(:role_1, on: other_user)
      refute permissions |> granted_role?(:role_2, on: other_user)
      assert permissions |> granted_role?(:role_3, on: other_user)
    end
  end

  describe "granted_to?/3" do
    test "returns true if the permission list meets conditions",
         %{task: task, permissions: permissions, user: user} do
      assert permissions |> granted_to?(user, role: :role_1, on: task)
      assert permissions |> granted_to?(user, role: :role_2, on: task)
      assert permissions |> granted_to?(user, role: :role_3, on: task)

      other_task = task_fixture()
      assert permissions |> granted_to?(user, role: :role_1, on: other_task)
      refute permissions |> granted_to?(user, role: :role_2, on: other_task)
      assert permissions |> granted_to?(user, role: :role_3, on: other_task)

      other_user = user_fixture()
      refute permissions |> granted_to?(user, role: :role_1, on: other_user)
      refute permissions |> granted_to?(user, role: :role_2, on: other_user)
      assert permissions |> granted_to?(user, role: :role_3, on: other_user)
    end
  end

  describe "granted_on?/3" do
    test "returns true if the permission list meets conditions",
         %{task: task, permissions: permissions, user: user} do
      assert permissions |> granted_on?(task, role: :role_1, to: user)
      assert permissions |> granted_on?(task, role: :role_2, to: user)
      assert permissions |> granted_on?(task, role: :role_3, to: user)

      other_task = task_fixture()
      assert permissions |> granted_on?(other_task, role: :role_1, to: user)
      refute permissions |> granted_on?(other_task, role: :role_2, to: user)
      assert permissions |> granted_on?(other_task, role: :role_3, to: user)

      other_user = user_fixture()
      refute permissions |> granted_on?(other_user, role: :role_1, to: user)
      refute permissions |> granted_on?(other_user, role: :role_2, to: user)
      assert permissions |> granted_on?(other_user, role: :role_3, to: user)
    end
  end
end
