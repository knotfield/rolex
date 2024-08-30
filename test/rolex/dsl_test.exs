defmodule Rolex.DSLTest do
  use Rolex.DataCase

  import Rolex.DSL

  alias Rolex.DSL

  describe "to_permission_params/1" do
    test "maps [role: #{inspect(@any)}] to %{}" do
      assert %{} == to_permission_params(%DSL{role: @any})
    end

    test "maps [role: <role>] to %{role: <role>}" do
      assert %{role: :some_role} == to_permission_params(%DSL{role: :some_role})
    end

    test "maps [from: #{inspect(@all)}] to %{subject_type: #{inspect(@all)}, subject_id: #{inspect(@all)}}" do
      assert %{subject_type: @all, subject_id: @all} == to_permission_params(%DSL{from: @all})
    end

    test "maps [from: #{inspect(@any)}] to %{}" do
      assert %{} == to_permission_params(%DSL{from: @any})
    end

    test "maps [from: <schema>] to %{subject_type: <schema>, subject_id: #{inspect(@all)}}" do
      assert %{subject_type: User, subject_id: @all} == to_permission_params(%DSL{from: User})
    end

    test "maps [from: {#{inspect(@any)}, <schema>}] to %{subject_type: <schema>}" do
      assert %{subject_type: User} == to_permission_params(%DSL{from: {:any, User}})
    end

    test "maps [from: <entity>] to %{subject_type: <schema>, subject_id: <id>}" do
      assert %{subject_type: User, subject_id: 1} ==
               to_permission_params(%DSL{from: %User{id: 1}})
    end

    test "maps [to: #{inspect(@all)}] to %{subject_type: #{inspect(@all)}, subject_id: #{inspect(@all)}}" do
      assert %{subject_type: @all, subject_id: @all} == to_permission_params(%DSL{to: @all})
    end

    test "maps [to: #{inspect(@any)}] to %{}" do
      assert %{} == to_permission_params(%DSL{to: @any})
    end

    test "maps [to: <schema>] to %{subject_type: <schema>, subject_id: #{inspect(@all)}}" do
      assert %{subject_type: User, subject_id: @all} == to_permission_params(%DSL{to: User})
    end

    test "maps [to: {#{inspect(@any)}, <schema>}] to %{subject_type: <schema>}" do
      assert %{subject_type: User} == to_permission_params(%DSL{to: {:any, User}})
    end

    test "maps [to: <entity>] to %{subject_type: <schema>, subject_id: <id>}" do
      assert %{subject_type: User, subject_id: 1} ==
               to_permission_params(%DSL{to: %User{id: 1}})
    end

    test "maps [on: #{inspect(@all)}] to %{object_type: #{inspect(@all)}, object_id: #{inspect(@all)}}" do
      assert %{object_type: @all, object_id: @all} == to_permission_params(%DSL{on: @all})
    end

    test "maps [on: #{inspect(@any)}] to %{}" do
      assert %{} == to_permission_params(%DSL{on: @any})
    end

    test "maps [on: <schema>] to %{object_type: <schema>, object_id: #{inspect(@all)}}" do
      assert %{object_type: User, object_id: @all} == to_permission_params(%DSL{on: User})
    end

    test "maps [on: {#{inspect(@any)}, <schema>}] to %{object_type: <schema>}" do
      assert %{object_type: User} == to_permission_params(%DSL{on: {:any, User}})
    end

    test "maps [on: <entity>] to %{object_type: <schema>, object_id: <id>}" do
      assert %{object_type: User, object_id: 1} ==
               to_permission_params(%DSL{on: %User{id: 1}})
    end
  end

  describe "changeset(:grant, opts)/2" do
    test "returns a valid changeset if options are valid" do
      assert %{valid?: true} = changeset(:grant, role: :some_role, to: @all, on: @all)
    end

    # test "permits only certain keys" do
    #   assert %{types: types} = changeset(:grant, [])
    #   assert [:on, :role, :to] = Map.keys(types) |> Enum.sort()
    # end

    test "disallows #{inspect(@any)} for any option value" do
      assert %{role: ["is invalid"], on: ["is invalid"], to: ["is invalid"]} =
               changeset(:grant, role: @any, to: @any, on: @any)
               |> errors_on()
    end

    test "requires options" do
      assert %{role: ["can't be blank"], to: ["can't be blank"], on: ["can't be blank"]} =
               changeset(:grant, [])
               |> errors_on()
    end
  end

  describe "changeset(:deny, opts)/2" do
    test "returns a valid changeset if options are valid" do
      assert %{valid?: true} = changeset(:deny, role: :some_role, to: @all, on: @all)
    end

    # test "permits only certain keys" do
    #   assert %{types: types} = changeset(:deny, [])
    #   assert [:on, :role, :to] = Map.keys(types) |> Enum.sort()
    # end

    test "disallows #{inspect(@any)} for any option value" do
      assert %{role: ["is invalid"], on: ["is invalid"], to: ["is invalid"]} =
               changeset(:deny, role: @any, to: @any, on: @any)
               |> errors_on()
    end

    test "requires options" do
      assert %{role: ["can't be blank"], to: ["can't be blank"], on: ["can't be blank"]} =
               changeset(:deny, [])
               |> errors_on()
    end
  end

  describe "changeset(:revoke, opts)/2" do
    test "returns a valid changeset if options are valid" do
      assert %{valid?: true} = changeset(:revoke, role: :some_role, from: @all, on: @all)
    end

    # test "permits only certain keys" do
    #   assert %{types: types} = changeset(:revoke, [])
    #   assert [:from, :on, :role] = Map.keys(types) |> Enum.sort()
    # end

    test "allows #{inspect(@any)} for any option value" do
      assert %{valid?: true} = changeset(:revoke, role: @any, from: @any, on: @any)
    end

    test "allows from: {#{inspect(@any)}, <schema>} and on: {#{inspect(@any)}, <schema>}" do
      assert %{valid?: true} =
               changeset(:revoke, role: @any, from: {@any, User}, on: {@any, Task})
    end

    test "requires options" do
      assert %{role: ["can't be blank"], from: ["can't be blank"], on: ["can't be blank"]} =
               changeset(:revoke, [])
               |> errors_on()
    end
  end

  describe "changeset(:filter, opts)/2" do
    test "returns a valid changeset if options are valid" do
      assert %{valid?: true} =
               changeset(:filter, role: :some_role, to: @all, on: @all)
    end

    # test "permits only certain keys" do
    #   assert %{types: types} = changeset(:filter, [])
    #   assert [:on, :role, :to] = Map.keys(types) |> Enum.sort()
    # end

    test "allows #{inspect(@any)} for any option value" do
      assert %{valid?: true} = changeset(:filter, role: @any, to: @any, on: @any)
    end

    test "allows to: <schema> and on: <schema>" do
      assert %{valid?: true} =
               changeset(:filter, to: User, on: Task)
    end

    test "allows to: {#{inspect(@any)}, <schema>} and on: {#{inspect(@any)}, <schema>}" do
      assert %{valid?: true} =
               changeset(:filter, to: {@any, User}, on: {@any, Task})
    end

    test "allows to: <entity> and on: <entity>" do
      assert %{valid?: true} =
               changeset(:filter, to: %User{id: 42}, on: %Task{id: 123})
    end

    test "requires no options" do
      assert %{valid?: true} = changeset(:filter, [])
    end
  end
end
