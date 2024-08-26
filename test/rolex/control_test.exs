defmodule Rolex.ControlTest do
  use Rolex.DataCase

  doctest Rolex.Control

  describe "grant/1" do
    test "upserts a grant permission to the configured repo and returns {:ok, %Permission{}}" do
      %{id: user_id, __struct__: user_type} = user = user_fixture()
      %{id: task_id, __struct__: task_type} = task = task_fixture()

      {:ok,
       %Permission{
         verb: :grant,
         role: :role_1,
         subject_type: ^user_type,
         subject_id: ^user_id,
         object_type: ^task_type,
         object_id: ^task_id
       }} = Rolex.grant(role: :role_1, to: user, on: task)
    end

    test "doesn't create a new grant permission if an identical one already exists" do
      attrs = %{role: :role_1, to: user_fixture(), on: task_fixture()}

      assert {:ok, permission} = Rolex.grant(attrs)
      assert {:ok, ^permission} = Rolex.grant(attrs)
    end
  end

  describe "grant_role/2" do
    test "upserts a grant permission to the configured repo and returns {:ok, %Permission{}}" do
      user = user_fixture()
      task = task_fixture()

      {:ok, :role_1} = Rolex.grant_role(:role_1, to: user, on: task)
    end
  end

  describe "grant_to/2" do
    test "upserts a grant permission to the configured repo and returns {:ok, subject}" do
      %{id: user_id, __struct__: user_type} = user = user_fixture()
      %{id: task_id, __struct__: task_type} = task = task_fixture()

      {:ok, ^user} = Rolex.grant_to(user, role: :role_1, on: task)

      assert [
               %Permission{
                 verb: :grant,
                 role: :role_1,
                 subject_type: ^user_type,
                 subject_id: ^user_id,
                 object_type: ^task_type,
                 object_id: ^task_id
               }
             ] = Repo.all(Permission)
    end
  end

  describe "grant_on/2" do
    test "upserts a grant permission to the configured repo and returns {:ok, object}" do
      %{id: user_id, __struct__: user_type} = user = user_fixture()
      %{id: task_id, __struct__: task_type} = task = task_fixture()

      {:ok, ^task} = Rolex.grant_on(task, role: :role_1, to: user)

      assert [
               %Permission{
                 verb: :grant,
                 role: :role_1,
                 subject_type: ^user_type,
                 subject_id: ^user_id,
                 object_type: ^task_type,
                 object_id: ^task_id
               }
             ] = Repo.all(Permission)
    end
  end

  describe "deny/1" do
    test "upserts a deny permission to the configured repo and returns {:ok, %Permission{}}" do
      %{id: user_id, __struct__: user_type} = user = user_fixture()
      %{id: task_id, __struct__: task_type} = task = task_fixture()

      {:ok,
       %Permission{
         verb: :deny,
         role: :role_1,
         subject_type: ^user_type,
         subject_id: ^user_id,
         object_type: ^task_type,
         object_id: ^task_id
       }} = Rolex.deny(role: :role_1, to: user, on: task)
    end

    test "doesn't create a new deny permission if an identical one already exists" do
      attrs = %{role: :role_1, to: user_fixture(), on: task_fixture()}

      assert {:ok, permission} = Rolex.deny(attrs)
      assert {:ok, ^permission} = Rolex.deny(attrs)
    end
  end

  describe "deny_role/2" do
    test "upserts a deny permission to the configured repo and returns {:ok, %Permission{}}" do
      user = user_fixture()
      task = task_fixture()

      {:ok, :role_1} = Rolex.deny_role(:role_1, to: user, on: task)
    end
  end

  describe "deny_to/2" do
    test "upserts a deny permission to the configured repo and returns {:ok, subject}" do
      %{id: user_id, __struct__: user_type} = user = user_fixture()
      %{id: task_id, __struct__: task_type} = task = task_fixture()

      {:ok, ^user} = Rolex.deny_to(user, role: :role_1, on: task)

      assert [
               %Permission{
                 verb: :deny,
                 role: :role_1,
                 subject_type: ^user_type,
                 subject_id: ^user_id,
                 object_type: ^task_type,
                 object_id: ^task_id
               }
             ] = Repo.all(Permission)
    end
  end

  describe "deny_on/2" do
    test "upserts a deny permission to the configured repo and returns {:ok, object}" do
      %{id: user_id, __struct__: user_type} = user = user_fixture()
      %{id: task_id, __struct__: task_type} = task = task_fixture()

      {:ok, ^task} = Rolex.deny_on(task, role: :role_1, to: user)

      assert [
               %Permission{
                 verb: :deny,
                 role: :role_1,
                 subject_type: ^user_type,
                 subject_id: ^user_id,
                 object_type: ^task_type,
                 object_id: ^task_id
               }
             ] = Repo.all(Permission)
    end
  end

  describe "revoke/1" do
    test "deletes matching permissions from the configured repo and returns {<deleted-count>, nil}" do
      user = user_fixture()
      task = task_fixture()

      Rolex.grant!(role: :role_1, to: user, on: task)
      Rolex.grant!(role: :role_1, to: user, on: task_fixture())

      {:ok, 1} = Rolex.revoke_from(user, role: :role_1, on: task)
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
               |> Rolex.multi_grant(role: :role_1)
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
               |> Rolex.multi_deny(role: :role_1)
               |> Ecto.Multi.to_list()
    end
  end

  describe "multi_revoke/2" do
    test "adds a revoke permission operation to an %Ecto.Multi{}" do
      assert [
               {_reference, {:delete_all, %Ecto.Query{}, []}}
             ] =
               Ecto.Multi.new()
               |> Rolex.multi_revoke(role: :role_1)
               |> Ecto.Multi.to_list()
    end
  end
end
