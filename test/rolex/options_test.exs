defmodule Rolex.OptionsTest do
  use Rolex.DataCase

  import Rolex.Options

  describe "changeset(:grant, opts)/2" do
    test "returns a valid changeset if options are valid" do
      assert %{valid?: true} =
               changeset(:grant, role: :some_role, to: :some_subject, on: :some_object)
    end

    test "permits only certain fields" do
      assert %{types: types} = changeset(:grant, [])
      assert [:on, :role, :to] = Map.keys(types) |> Enum.sort()
    end

    test "disallows #{@any} for any option value" do
      assert %{valid?: false} =
               changeset =
               changeset(:grant, role: @any, to: @any, on: @any)

      assert %{role: ["is reserved"], on: ["is reserved"], to: ["is reserved"]} =
               errors_on(changeset)
    end

    test "requires options" do
      assert %{valid?: false} = changeset = changeset(:grant, [])

      assert %{role: ["can't be blank"], to: ["can't be blank"], on: ["can't be blank"]} =
               errors_on(changeset)
    end
  end

  describe "changeset(:deny, opts)/2" do
    test "returns a valid changeset if options are valid" do
      assert %{valid?: true} =
               changeset(:deny, role: :some_role, to: :some_subject, on: :some_object)
    end

    test "permits only certain fields" do
      assert %{types: types} = changeset(:deny, [])
      assert [:on, :role, :to] = Map.keys(types) |> Enum.sort()
    end

    test "disallows #{@any} for any option value" do
      assert %{valid?: false} =
               changeset =
               changeset(:deny, role: @any, to: @any, on: @any)

      assert %{role: ["is reserved"], on: ["is reserved"], to: ["is reserved"]} =
               errors_on(changeset)
    end

    test "requires options" do
      assert %{valid?: false} = changeset = changeset(:deny, [])

      assert %{role: ["can't be blank"], to: ["can't be blank"], on: ["can't be blank"]} =
               errors_on(changeset)
    end
  end

  describe "changeset(:revoke, opts)/2" do
    test "returns a valid changeset if options are valid" do
      assert %{valid?: true} =
               changeset(:revoke, role: :some_role, from: :some_subject, on: :some_object)
    end

    test "permits only certain fields" do
      assert %{types: types} = changeset(:revoke, [])
      assert [:from, :on, :role] = Map.keys(types) |> Enum.sort()
    end

    test "requires options" do
      assert %{valid?: false} = changeset = changeset(:revoke, [])

      assert %{role: ["can't be blank"], from: ["can't be blank"], on: ["can't be blank"]} =
               errors_on(changeset)
    end
  end

  describe "changeset(:filter, opts)/2" do
    test "returns a valid changeset if options are valid" do
      assert %{valid?: true} =
               changeset(:filter, role: :some_role, to: :some_subject, on: :some_object)
    end

    test "permits only certain fields" do
      assert %{types: types} = changeset(:filter, [])
      assert [:on, :role, :to] = Map.keys(types) |> Enum.sort()
    end

    test "requires options" do
      assert %{valid?: false} = changeset = changeset(:filter, [])

      assert %{role: ["can't be blank"], to: ["can't be blank"], on: ["can't be blank"]} =
               errors_on(changeset)
    end
  end
end
