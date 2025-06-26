defmodule TragarCms.QuoteSync do
  @moduledoc """
  GenServer for periodically syncing quotes from the Tragar API.
  """
  use GenServer
  require Logger

  alias TragarCms.{TragarApi, Quotes}

  # Sync every 30 minutes (30 * 60 * 1000 milliseconds)
  @sync_interval 30 * 60 * 1000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Manually trigger a sync from the API.
  """
  def sync_now do
    GenServer.cast(__MODULE__, :sync_quotes)
  end

  @doc """
  Get the last sync status and time.
  """
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @impl true
  def init(_opts) do
    # Schedule the first sync after 10 seconds
    Process.send_after(self(), :sync_quotes, 10_000)

    {:ok,
     %{
       last_sync: nil,
       status: :idle,
       error: nil
     }}
  end

  @impl true
  def handle_info(:sync_quotes, state) do
    # Schedule next sync
    Process.send_after(self(), :sync_quotes, @sync_interval)

    # Perform sync
    new_state = perform_sync(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:sync_quotes, state) do
    new_state = perform_sync(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state, state}
  end

  defp perform_sync(state) do
    Logger.info("Starting quote sync from Tragar API")

    case TragarApi.fetch_quotes(limit: 5) do
      {:ok, quotes} ->
        created_count =
          quotes
          |> Enum.map(&Quotes.create_quote/1)
          |> Enum.count(fn
            {:ok, _} -> true
            {:error, _} -> false
          end)

        # Broadcast sync completion
        Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:sync_completed, created_count})

        Logger.info("Quote sync completed: #{created_count} new quotes added")

        %{state | last_sync: DateTime.utc_now(), status: :success, error: nil}

      {:error, reason} ->
        Logger.error("Quote sync failed: #{reason}")

        %{state | last_sync: DateTime.utc_now(), status: :error, error: reason}
    end
  end
end
