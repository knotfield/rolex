defmodule Rolex.ControlTest do
  use Rolex.DataCase

  import Rolex.Control

  defp prepare_for_revoke_tests(_context) do
    [user_1, user_2] = user_fixtures(2)
    [task_1, task_2] = task_fixtures(2)

    grant_role!(:role_1, to: @all, on: Task)
    grant_role!(:role_2, to: User, on: task_1)
    grant_role!(:role_3, to: user_1, on: @all)

    %{user_1: user_1, user_2: user_2, task_1: task_1, task_2: task_2}
  end

  describe "grant/1" do
    test "returns {:error, changeset} if opts are invalid" do
      assert {:error, %Ecto.Changeset{}} = grant([])
    end

    test "upserts a grant permission to the configured repo and returns :ok" do
      user = user_fixture()
      task = task_fixture()

      assert :ok = grant(role: :role_1, to: user, on: task)

      assert Repo.get_by(Permission,
               verb: :grant,
               role: :role_1,
               subject_type: User,
               subject_id: user.id,
               object_type: Task,
               object_id: task.id
             )
    end

    test "doesn't create a new grant permission if an identical one already exists" do
      attrs = %{role: :role_1, to: user_fixture(), on: task_fixture()}

      :ok = grant(attrs)
      [permission] = Repo.all(Permission)
      :ok = grant(attrs)
      assert [^permission] = Repo.all(Permission)
    end
  end

  describe "grant_role/2" do
    test "upserts a grant permission to the configured repo and returns {:ok, role}" do
      user = user_fixture()
      task = task_fixture()

      assert {:ok, :role_1} = grant_role(:role_1, to: user, on: task)

      assert Repo.get_by(Permission,
               verb: :grant,
               role: :role_1,
               subject_type: User,
               subject_id: user.id,
               object_type: Task,
               object_id: task.id
             )
    end
  end

  describe "grant_to/2" do
    test "upserts a grant permission to the configured repo and returns {:ok, subject}" do
      user = user_fixture()
      task = task_fixture()

      assert {:ok, ^user} = grant_to(user, role: :role_1, on: task)

      assert Repo.get_by(Permission,
               verb: :grant,
               role: :role_1,
               subject_type: User,
               subject_id: user.id,
               object_type: Task,
               object_id: task.id
             )
    end
  end

  describe "grant_on/2" do
    test "upserts a grant permission to the configured repo and returns {:ok, object}" do
      user = user_fixture()
      task = task_fixture()

      assert {:ok, ^task} = grant_on(task, role: :role_1, to: user)

      assert Repo.get_by(Permission,
               verb: :grant,
               role: :role_1,
               subject_type: User,
               subject_id: user.id,
               object_type: Task,
               object_id: task.id
             )
    end
  end

  describe "deny/1" do
    test "returns {:error, changeset} if opts are invalid" do
      assert {:error, %Ecto.Changeset{}} = deny([])
    end

    test "upserts a deny permission to the configured repo and returns :ok" do
      user = user_fixture()
      task = task_fixture()

      assert :ok = deny(role: :role_1, to: user, on: task)

      assert Repo.get_by(Permission,
               verb: :deny,
               role: :role_1,
               subject_type: User,
               subject_id: user.id,
               object_type: Task,
               object_id: task.id
             )
    end

    test "doesn't create a new deny permission if an identical one already exists" do
      attrs = %{role: :role_1, to: user_fixture(), on: task_fixture()}

      :ok = deny(attrs)
      [permission] = Repo.all(Permission)
      :ok = deny(attrs)
      assert [^permission] = Repo.all(Permission)
    end
  end

  describe "deny_role/2" do
    test "upserts a deny permission to the configured repo and returns {:ok, role}" do
      user = user_fixture()
      task = task_fixture()

      assert {:ok, :role_1} = deny_role(:role_1, to: user, on: task)

      assert Repo.get_by(Permission,
               verb: :deny,
               role: :role_1,
               subject_type: User,
               subject_id: user.id,
               object_type: Task,
               object_id: task.id
             )
    end
  end

  describe "deny_to/2" do
    test "upserts a deny permission to the configured repo and returns {:ok, subject}" do
      user = user_fixture()
      task = task_fixture()

      assert {:ok, ^user} = deny_to(user, role: :role_1, on: task)

      assert Repo.get_by(Permission,
               verb: :deny,
               role: :role_1,
               subject_type: User,
               subject_id: user.id,
               object_type: Task,
               object_id: task.id
             )
    end
  end

  describe "deny_on/2" do
    test "upserts a deny permission to the configured repo and returns {:ok, object}" do
      user = user_fixture()
      task = task_fixture()

      assert {:ok, ^task} = deny_on(task, role: :role_1, to: user)

      assert Repo.get_by(Permission,
               verb: :deny,
               role: :role_1,
               subject_type: User,
               subject_id: user.id,
               object_type: Task,
               object_id: task.id
             )
    end
  end

  describe "revoke/1" do
    setup [:prepare_for_revoke_tests]

    test "returns {:error, changeset} if opts are invalid" do
      assert {:error, %{valid?: false}} = revoke([])
    end

    test "deletes matching permissions from the configured repo and returns {:ok, <deleted-count>}",
         %{user_1: user_1, task_1: task_1} do
      assert {:ok, 1} = revoke(role: :role_1, from: @all, on: Task)
      assert {:ok, 1} = revoke(role: :role_2, from: User, on: task_1)
      assert {:ok, 1} = revoke(role: :role_3, from: user_1, on: @all)
      assert [] = Repo.all(Permission)
    end
  end

  describe "revoke_role/2" do
    setup [:prepare_for_revoke_tests]

    test "deletes matching permissions from the configured repo and returns {:ok, role}",
         %{user_1: user_1, task_1: task_1} do
      assert {:ok, :role_1} = revoke_role(:role_1, from: @all, on: Task)
      assert {:ok, :role_2} = revoke_role(:role_2, from: User, on: task_1)
      assert {:ok, :role_3} = revoke_role(:role_3, from: user_1, on: @all)
      assert [] = Repo.all(Permission)
    end
  end

  describe "revoke_from/2" do
    setup [:prepare_for_revoke_tests]

    test "deletes matching permissions from the configured repo and returns {:ok, subject}",
         %{user_1: user_1, task_1: task_1} do
      assert {:ok, @all} = revoke_from(@all, role: :role_1, on: Task)
      assert {:ok, User} = revoke_from(User, role: :role_2, on: task_1)
      assert {:ok, ^user_1} = revoke_from(user_1, role: :role_3, on: @all)
      assert [] = Repo.all(Permission)
    end
  end

  describe "revoke_on/2" do
    setup [:prepare_for_revoke_tests]

    test "deletes matching permissions from the configured repo and returns {:ok, object}",
         %{user_1: user_1, task_1: task_1} do
      assert {:ok, Task} = revoke_on(Task, role: :role_1, from: @all)
      assert {:ok, ^task_1} = revoke_on(task_1, role: :role_2, from: User)
      assert {:ok, @all} = revoke_on(@all, role: :role_3, from: user_1)
      assert [] = Repo.all(Permission)
    end
  end

  describe "multi_grant/2" do
    test "adds a grant permission operation to an %Ecto.Multi{}" do
      assert [
               {_reference,
                {:insert, %{valid?: true},
                 [
                   on_conflict: [set: [verb: :grant]],
                   conflict_target: _,
                   returning: true
                 ]}}
             ] =
               Ecto.Multi.new()
               |> multi_grant(role: :role_1, to: @all, on: @all)
               |> Ecto.Multi.to_list()
    end
  end

  describe "multi_grant_role/3" do
    test "adds a grant permission operation to an %Ecto.Multi{}" do
      assert [
               {_reference,
                {:insert, %{valid?: true},
                 [
                   on_conflict: [set: [verb: :grant]],
                   conflict_target: _,
                   returning: true
                 ]}}
             ] =
               Ecto.Multi.new()
               |> multi_grant_role(:role_1, to: @all, on: @all)
               |> Ecto.Multi.to_list()
    end
  end

  describe "multi_deny/2" do
    test "adds a deny permission operation to an %Ecto.Multi{}" do
      assert [
               {_reference,
                {:insert, %{valid?: true},
                 [
                   on_conflict: [set: [verb: :deny]],
                   conflict_target: _,
                   returning: true
                 ]}}
             ] =
               Ecto.Multi.new()
               |> multi_deny(role: :role_1, to: @all, on: @all)
               |> Ecto.Multi.to_list()
    end
  end

  describe "multi_revoke/2" do
    test "adds a revoke permission operation to an %Ecto.Multi{}" do
      assert [
               {_reference, {:delete_all, %Ecto.Query{}, []}}
             ] =
               Ecto.Multi.new()
               |> multi_revoke(role: :role_1, from: @all, on: @all)
               |> Ecto.Multi.to_list()
    end
  end
end
