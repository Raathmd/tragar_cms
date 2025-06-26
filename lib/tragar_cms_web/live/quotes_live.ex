defmodule TragarCmsWeb.QuotesLive do
  use TragarCmsWeb, :live_view

  alias TragarCms.Quotes
  alias TragarCms.Quotes.Quote
  alias TragarCms.QuoteSync

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TragarCms.PubSub, "quotes")
    end

    quotes = Quotes.list_quotes()
    stats = Quote.get_stats(quotes)
    sync_status = get_sync_status_safely()

    {:ok,
     socket
     |> assign(:quotes, quotes)
     |> assign(:stats, stats)
     |> assign(:sync_status, sync_status)
     |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
     |> assign(:show_form, false)}
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :show_form, !socket.assigns.show_form)}
  end

  @impl true
  def handle_event("sync_from_tragar", _params, socket) do
    QuoteSync.sync_now()

    {:noreply,
     socket
     |> put_flash(:info, "Syncing quotes from Tragar API...")
     |> assign(:sync_status, %{status: :syncing, last_sync: DateTime.utc_now(), error: nil})}
  end

  @impl true
  def handle_event("validate", %{"quote" => quote_params}, socket) do
    changeset =
      %Quote{}
      |> Quotes.change_quote(quote_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"quote" => quote_params}, socket) do
    case Quotes.create_quote(quote_params) do
      {:ok, quote} ->
        Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_created, quote})

        quotes = Quotes.list_quotes()
        stats = Quote.get_stats(quotes)

        {:noreply,
         socket
         |> assign(:quotes, quotes)
         |> assign(:stats, stats)
         |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
         |> assign(:show_form, false)
         |> put_flash(:info, "Quote created successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    quote = Quotes.get_quote!(id)
    {:ok, _} = Quotes.delete_quote(quote)

    Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_deleted, quote})

    quotes = Quotes.list_quotes()
    stats = Quote.get_stats(quotes)

    {:noreply,
     socket
     |> assign(:quotes, quotes)
     |> assign(:stats, stats)
     |> put_flash(:info, "Quote deleted successfully!")}
  end

  @impl true
  def handle_info({:quote_created, _quote}, socket) do
    quotes = Quotes.list_quotes()
    stats = Quote.get_stats(quotes)

    {:noreply,
     socket
     |> assign(:quotes, quotes)
     |> assign(:stats, stats)}
  end

  @impl true
  def handle_info({:quote_deleted, _quote}, socket) do
    quotes = Quotes.list_quotes()
    stats = Quote.get_stats(quotes)

    {:noreply,
     socket
     |> assign(:quotes, quotes)
     |> assign(:stats, stats)}
  end

  @impl true
  def handle_info({:sync_completed, created_count}, socket) do
    quotes = Quotes.list_quotes()
    stats = Quote.get_stats(quotes)
    sync_status = get_sync_status_safely()

    message =
      if created_count > 0 do
        "Successfully synced #{created_count} new quotes from Tragar API!"
      else
        "Sync complete - no new quotes found."
      end

    {:noreply,
     socket
     |> assign(:quotes, quotes)
     |> assign(:stats, stats)
     |> assign(:sync_status, sync_status)
     |> put_flash(:info, message)}
  end
end
