defmodule TragarCmsWeb.DashboardLive do
  use TragarCmsWeb, :live_view

  alias TragarCms.Quotes
  alias TragarCms.Quotes.Quote

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TragarCms.PubSub, "quotes")
    end

    socket =
      socket
      |> assign(:show_form, false)
      |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
      |> load_quotes()
      |> calculate_stats()

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :show_form, !socket.assigns.show_form)}
  end

  @impl true
  def handle_event("validate", %{"quote" => quote_params}, socket) do
    changeset = Quotes.change_quote(%Quote{}, quote_params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"quote" => quote_params}, socket) do
    case Quotes.create_quote(quote_params) do
      {:ok, quote} ->
        Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_created, quote})

        socket =
          socket
          |> assign(:show_form, false)
          |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
          |> put_flash(:info, "Quote created successfully")
          |> load_quotes()
          |> calculate_stats()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    quote = Quotes.get_quote!(id)
    {:ok, _} = Quotes.delete_quote(quote)

    Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_deleted, quote})

    socket =
      socket
      |> put_flash(:info, "Quote deleted successfully")
      |> load_quotes()
      |> calculate_stats()

    {:noreply, socket}
  end

  @impl true
  def handle_event("accept", %{"id" => id}, socket) do
    quote = Quotes.get_quote!(id)
    {:ok, updated_quote} = Quotes.update_quote(quote, %{status: "accepted"})

    Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_updated, updated_quote})

    socket =
      socket
      |> put_flash(:info, "Quote accepted successfully")
      |> load_quotes()
      |> calculate_stats()

    {:noreply, socket}
  end

  @impl true
  def handle_event("reject", %{"id" => id}, socket) do
    quote = Quotes.get_quote!(id)
    {:ok, updated_quote} = Quotes.update_quote(quote, %{status: "rejected"})

    Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_updated, updated_quote})

    socket =
      socket
      |> put_flash(:info, "Quote rejected successfully")
      |> load_quotes()
      |> calculate_stats()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:quote_created, _quote}, socket) do
    socket =
      socket
      |> load_quotes()
      |> calculate_stats()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:quote_updated, _quote}, socket) do
    socket =
      socket
      |> load_quotes()
      |> calculate_stats()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:quote_deleted, _quote}, socket) do
    socket =
      socket
      |> load_quotes()
      |> calculate_stats()

    {:noreply, socket}
  end

  defp load_quotes(socket) do
    quotes = Quotes.list_quotes()
    assign(socket, :quotes, quotes)
  end

  defp calculate_stats(socket) do
    quotes = socket.assigns.quotes

    total_quotes = length(quotes)

    pending_quotes = Enum.count(quotes, fn quote -> quote.status == "pending" end)
    accepted_quotes = Enum.count(quotes, fn quote -> quote.status == "accepted" end)
    rejected_quotes = Enum.count(quotes, fn quote -> quote.status == "rejected" end)

    # Calculate total value of all quotes
    total_value =
      quotes
      |> Enum.map(fn quote ->
        case quote.total_amount do
          nil ->
            Decimal.new(0)

          amount when is_binary(amount) ->
            case Decimal.parse(amount) do
              {decimal, _} -> decimal
              :error -> Decimal.new(0)
            end

          amount ->
            amount
        end
      end)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    # Calculate average quote value
    avg_value =
      if total_quotes > 0 do
        Decimal.div(total_value, total_quotes)
      else
        Decimal.new(0)
      end

    # Calculate pending value (value of quotes awaiting decision)
    pending_value =
      quotes
      |> Enum.filter(fn quote -> quote.status == "pending" end)
      |> Enum.map(fn quote ->
        case quote.total_amount do
          nil ->
            Decimal.new(0)

          amount when is_binary(amount) ->
            case Decimal.parse(amount) do
              {decimal, _} -> decimal
              :error -> Decimal.new(0)
            end

          amount ->
            amount
        end
      end)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

    socket
    |> assign(:total_quotes, total_quotes)
    |> assign(:pending_quotes, pending_quotes)
    |> assign(:accepted_quotes, accepted_quotes)
    |> assign(:rejected_quotes, rejected_quotes)
    |> assign(:total_value, total_value)
    |> assign(:avg_value, avg_value)
    |> assign(:pending_value, pending_value)
  end

  defp format_currency(decimal_value) do
    case Decimal.to_string(decimal_value, :normal) do
      "0" ->
        "R0.00"

      value ->
        # Convert to float for formatting, then back to string
        float_value = Decimal.to_float(decimal_value)

        :erlang.float_to_binary(float_value, decimals: 2)
        |> then(fn formatted -> "R#{formatted}" end)
    end
  rescue
    _ -> "R0.00"
  end
end
