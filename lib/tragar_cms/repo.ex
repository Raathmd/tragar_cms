defmodule TragarCms.Repo do
  use Ecto.Repo,
    otp_app: :tragar_cms,
    adapter: Ecto.Adapters.Postgres
end
