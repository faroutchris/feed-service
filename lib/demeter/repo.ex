defmodule Demeter.Repo do
  use Ecto.Repo,
    otp_app: :demeter,
    adapter: Ecto.Adapters.Postgres
end
