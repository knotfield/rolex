defmodule Rolex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Rolex.Repo
    ]

    opts = [strategy: :one_for_one, name: :rolex]
    Supervisor.start_link(children, opts)
  end
end
