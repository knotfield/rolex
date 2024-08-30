defmodule Rolex.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Rolex.DataCase

      alias Rolex.Permission
      alias Rolex.Repo
      alias Rolex.Task
      alias Rolex.User

      @all Application.compile_env(:rolex, :all_atom, :all)
      @any Application.compile_env(:rolex, :any_atom, :any)

      def user_fixture(attrs \\ %{}) do
        struct(User, attrs) |> Repo.insert!()
      end

      def user_fixtures(n), do: for(_i <- 1..n//1, do: user_fixture()) |> Enum.sort_by(& &1.id)

      def task_fixture(attrs \\ %{}) do
        struct(Task, attrs) |> Repo.insert!()
      end

      def task_fixtures(n), do: for(_i <- 1..n//1, do: task_fixture()) |> Enum.sort_by(& &1.id)
    end
  end

  setup tags do
    Rolex.DataCase.setup_sandbox(tags)
    :ok
  end

  # setup do
  #   old_repo = Application.get_env(:rolex, :repo)
  #   Application.put_env(:rolex, :repo, Rolex.Repo)

  #   on_exit(fn ->
  #     Application.put_env(:rolex, :repo, old_repo)
  #   end)
  # end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Rolex.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
