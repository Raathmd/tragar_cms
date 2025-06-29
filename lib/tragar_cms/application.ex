defmodule TragarCms.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TragarCmsWeb.Telemetry,
      TragarCms.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:tragar_cms, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:tragar_cms, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TragarCms.PubSub},
      # Start the quote sync worker
      TragarCms.QuoteSync,
      # Start a worker by calling: TragarCms.Worker.start_link(arg)
      # {TragarCms.Worker, arg},
      # Start to serve requests, typically the last entry
      TragarCmsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TragarCms.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TragarCmsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, migrations are run when using a release for PostgreSQL
    System.get_env("RELEASE_NAME") == nil
  end
end
