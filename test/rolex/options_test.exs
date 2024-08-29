defmodule Rolex.OptionsTest do
  use Rolex.DataCase

  import Rolex.Options

  describe "changeset(:grant, opts)/2" do
    test "returns a valid changeset if options are valid" do
      assert %{valid?: true} = changeset(:grant, role: :some_role, to: @all, on: @all)
    end

    test "permits only certain keys" do
      assert %{types: types} = changeset(:grant, [])
      assert [:on, :role, :to] = Map.keys(types) |> Enum.sort()
    end

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

    test "permits only certain keys" do
      assert %{types: types} = changeset(:deny, [])
      assert [:on, :role, :to] = Map.keys(types) |> Enum.sort()
    end

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

    test "permits only certain keys" do
      assert %{types: types} = changeset(:revoke, [])
      assert [:from, :on, :role] = Map.keys(types) |> Enum.sort()
    end

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

    test "permits only certain keys" do
      assert %{types: types} = changeset(:filter, [])
      assert [:on, :role, :to] = Map.keys(types) |> Enum.sort()
    end

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
