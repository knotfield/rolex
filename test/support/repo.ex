defmodule Rolex.Repo do
  use Ecto.Repo,
    otp_app: :rolex,
    adapter: Ecto.Adapters.Postgres
end
