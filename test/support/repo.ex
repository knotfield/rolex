defmodule Rolex.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :rolex,
    adapter: Ecto.Adapters.Postgres
end
