defmodule TragarCms.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Ensure database directory exists before starting
    ensure_database_directory()

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
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end

  defp ensure_database_directory() do
    # Get the database path from configuration
    database_path = Application.get_env(:tragar_cms, TragarCms.Repo)[:database]

    if database_path do
      # Extract directory from database file path
      database_dir = Path.dirname(database_path)

      # Create directory if it doesn't exist
      case File.mkdir_p(database_dir) do
        :ok ->
          IO.puts("Database directory ensured: #{database_dir}")

        {:error, reason} ->
          IO.puts("Warning: Could not create database directory #{database_dir}: #{reason}")
      end
    end
  end
end
