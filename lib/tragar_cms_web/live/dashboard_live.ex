defmodule TragarCmsWeb.DashboardLive do
  use TragarCmsWeb, :live_view

  alias TragarCms.Quotes
  alias TragarCms.Quotes.Quote
  alias TragarCms.TragarApi

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
  def handle_event("save", %{"quote" => quote_params, "action" => action}, socket) do
    case action do
      "quick_quote" ->
        handle_quick_quote(quote_params, socket)

      "full_quote" ->
        handle_full_quote(quote_params, socket)

      _other ->
        handle_regular_quote(quote_params, socket)
    end
  end

  @impl true
  def handle_event("save", %{"quote" => quote_params}, socket) do
    handle_regular_quote(quote_params, socket)
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

  # Handle quick quote request to FreightWare API
  defp handle_quick_quote(quote_params, socket) do
    shipment_data = build_shipment_data(quote_params)

    case TragarApi.quick_quote(shipment_data) do
      {:ok, response} ->
        # Save the quick quote response to local database
        quick_quote_attrs = %{
          "author" => "FreightWare API",
          "content" =>
            "Quick Quote: #{Map.get(quote_params, "consignor_name", "Unknown")} to #{Map.get(quote_params, "consignee_name", "Unknown")}",
          "status" => "pending",
          "total_amount" => extract_total_amount_from_response(response),
          "quote_type" => "quick_quote",
          "api_response" => Jason.encode!(response)
        }

        case Quotes.create_quote(quick_quote_attrs) do
          {:ok, quote} ->
            Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_created, quote})

            socket =
              socket
              |> assign(:show_form, false)
              |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
              |> put_flash(:info, "Quick quote retrieved successfully")
              |> load_quotes()
              |> calculate_stats()

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
        end

      {:error, reason} ->
        socket =
          socket
          |> put_flash(:error, "Failed to get quick quote: #{reason}")

        {:noreply, socket}
    end
  end

  # Handle full quote creation to FreightWare API
  defp handle_full_quote(quote_params, socket) do
    quote_data = build_quote_data(quote_params)

    case TragarApi.create_quote(quote_data) do
      {:ok, response} ->
        # Save the full quote to local database
        full_quote_attrs = %{
          "author" => "FreightWare API",
          "content" =>
            "Full Quote: #{Map.get(quote_params, "consignor_name", "Unknown")} to #{Map.get(quote_params, "consignee_name", "Unknown")}",
          "status" => "pending",
          "total_amount" => extract_total_amount_from_response(response),
          "quote_type" => "quote",
          "api_response" => Jason.encode!(response)
        }

        case Quotes.create_quote(full_quote_attrs) do
          {:ok, quote} ->
            Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_created, quote})

            socket =
              socket
              |> assign(:show_form, false)
              |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
              |> put_flash(:info, "Full quote created successfully")
              |> load_quotes()
              |> calculate_stats()

            {:noreply, socket}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
        end

      {:error, reason} ->
        socket =
          socket
          |> put_flash(:error, "Failed to create full quote: #{reason}")

        {:noreply, socket}
    end
  end

  # Handle regular quote creation (local only)
  defp handle_regular_quote(quote_params, socket) do
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

  # Build shipment data for quick quote API call
  defp build_shipment_data(quote_params) do
    %{
      "consignorSuburb" => Map.get(quote_params, "consignor_suburb", ""),
      "consignorCity" => Map.get(quote_params, "consignor_city", ""),
      "consignorPostalCode" => Map.get(quote_params, "consignor_postal_code", ""),
      "consigneeSuburb" => Map.get(quote_params, "consignee_suburb", ""),
      "consigneeCity" => Map.get(quote_params, "consignee_city", ""),
      "consigneePostalCode" => Map.get(quote_params, "consignee_postal_code", ""),
      "serviceType" => Map.get(quote_params, "service_type", ""),
      "totalQuantity" => parse_integer(Map.get(quote_params, "item_quantity", "1")),
      "totalWeight" => parse_decimal(Map.get(quote_params, "item_weight", "0.1")),
      "length" => parse_decimal(Map.get(quote_params, "item_length", "10")),
      "width" => parse_decimal(Map.get(quote_params, "item_width", "10")),
      "height" => parse_decimal(Map.get(quote_params, "item_height", "10"))
    }
  end

  # Build quote data for full quote API call
  defp build_quote_data(quote_params) do
    %{
      "consignor_name" => Map.get(quote_params, "consignor_name", ""),
      "consignor_building" => Map.get(quote_params, "consignor_building", ""),
      "consignor_street" => Map.get(quote_params, "consignor_street", ""),
      "consignor_suburb" => Map.get(quote_params, "consignor_suburb", ""),
      "consignor_city" => Map.get(quote_params, "consignor_city", ""),
      "consignor_postal_code" => Map.get(quote_params, "consignor_postal_code", ""),
      "consignor_contact_name" => Map.get(quote_params, "consignor_contact_name", ""),
      "consignor_contact_tel" => Map.get(quote_params, "consignor_contact_tel", ""),
      "consignee_name" => Map.get(quote_params, "consignee_name", ""),
      "consignee_building" => Map.get(quote_params, "consignee_building", ""),
      "consignee_street" => Map.get(quote_params, "consignee_street", ""),
      "consignee_suburb" => Map.get(quote_params, "consignee_suburb", ""),
      "consignee_city" => Map.get(quote_params, "consignee_city", ""),
      "consignee_postal_code" => Map.get(quote_params, "consignee_postal_code", ""),
      "consignee_contact_name" => Map.get(quote_params, "consignee_contact_name", ""),
      "consignee_contact_tel" => Map.get(quote_params, "consignee_contact_tel", ""),
      "service_type" => Map.get(quote_params, "service_type", ""),
      "shipper_reference" => Map.get(quote_params, "shipper_reference", ""),
      "value_declared" => parse_decimal(Map.get(quote_params, "value_declared", "0")),
      "collection_instructions" => Map.get(quote_params, "collection_instructions", ""),
      "delivery_instructions" => Map.get(quote_params, "delivery_instructions", ""),
      "total_quantity" => parse_integer(Map.get(quote_params, "item_quantity", "1")),
      "total_weight" => parse_decimal(Map.get(quote_params, "item_weight", "0.1")),
      "items" => [
        %{
          "quantity" => parse_integer(Map.get(quote_params, "item_quantity", "1")),
          "weight" => parse_decimal(Map.get(quote_params, "item_weight", "0.1")),
          "length" => parse_decimal(Map.get(quote_params, "item_length", "10")),
          "width" => parse_decimal(Map.get(quote_params, "item_width", "10")),
          "height" => parse_decimal(Map.get(quote_params, "item_height", "10")),
          "description" => Map.get(quote_params, "item_description", "")
        }
      ]
    }
  end

  # Extract total amount from API response
  defp extract_total_amount_from_response(response) do
    cond do
      # For quick quote response (esRates format)
      is_map(response) and Map.has_key?(response, "response") ->
        case Map.get(response, "response") do
          %{"esRates" => rates_data} when is_binary(rates_data) ->
            case Jason.decode(rates_data) do
              {:ok, %{"Rate" => rates}} when is_list(rates) ->
                rates
                |> Enum.map(&Map.get(&1, "totalCharge", 0))
                |> Enum.max(fn -> 0 end)
                |> Decimal.new()

              _ ->
                Decimal.new(0)
            end

          %{"esQuotes" => quotes_data} when is_binary(quotes_data) ->
            case Jason.decode(quotes_data) do
              {:ok, %{"Quotes" => quotes}} when is_list(quotes) ->
                quotes
                |> List.first(%{})
                |> Map.get("chargedAmount", 0)
                |> Decimal.new()

              _ ->
                Decimal.new(0)
            end

          _ ->
            Decimal.new(0)
        end

      true ->
        Decimal.new(0)
    end
  rescue
    _ -> Decimal.new(0)
  end

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 1
    end
  end

  defp parse_integer(value) when is_integer(value), do: value
  defp parse_integer(_), do: 1

  defp parse_decimal(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> 0.1
    end
  end

  defp parse_decimal(value) when is_number(value), do: value
  defp parse_decimal(_), do: 0.1

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

      _formatted_value ->
        # Convert to float for formatting, then back to string
        float_value = Decimal.to_float(decimal_value)

        :erlang.float_to_binary(float_value, decimals: 2)
        |> then(fn formatted -> "R#{formatted}" end)
    end
  rescue
    _ -> "R0.00"
  end
end
