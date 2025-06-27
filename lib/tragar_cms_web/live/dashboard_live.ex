defmodule TragarCmsWeb.DashboardLive do
  use TragarCmsWeb, :live_view

  alias TragarCms.Quotes
  alias TragarCms.Quotes.Quote
  alias TragarCms.TragarApi
  alias TragarCms.Accounts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TragarCms.PubSub, "quotes")
    end

    # For now, we'll use a hardcoded organization ID until authentication is added
    organization_id = "demo-org-123"
    account_references = Accounts.list_account_references_for_organization(organization_id)
    default_account_reference = Accounts.get_default_account_reference(organization_id)

    socket =
      socket
      |> assign(:show_form, false)
      |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
      |> assign(:items, [])
      |> assign(:organization_id, organization_id)
      |> assign(:account_references, account_references)
      |> assign(
        :selected_account_reference_id,
        if(default_account_reference, do: default_account_reference.id, else: nil)
      )
      |> load_quotes()
      |> calculate_stats()

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, !socket.assigns.show_form)
     |> assign(:items, [])}
  end

  @impl true
  def handle_event("add_item", _params, socket) do
    new_item = %{
      "description" => "",
      "quantity" => "",
      "weight" => "",
      "length" => "",
      "width" => "",
      "height" => "",
      "unit_value" => "",
      "package_type" => "",
      "special_handling" => "",
      "special_instructions" => ""
    }

    items = socket.assigns.items ++ [new_item]
    {:noreply, assign(socket, :items, items)}
  end

  @impl true
  def handle_event("remove_item", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    items = socket.assigns.items |> List.delete_at(index)
    {:noreply, assign(socket, :items, items)}
  end

  @impl true
  def handle_event("validate", %{"quote" => quote_params} = params, socket) do
    # Extract items from params if present
    items = extract_items_from_params(params)

    # Update selected account reference if changed
    selected_account_reference_id =
      Map.get(quote_params, "account_reference_id", socket.assigns.selected_account_reference_id)

    changeset =
      %Quote{}
      |> Quotes.change_quote(quote_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(:items, items)
     |> assign(:selected_account_reference_id, selected_account_reference_id)}
  end

  @impl true
  def handle_event("save", %{"quote" => quote_params} = params, socket) do
    # Get the selected account reference for API credentials
    account_reference_id =
      Map.get(quote_params, "account_reference_id", socket.assigns.selected_account_reference_id)

    account_reference =
      if account_reference_id do
        Accounts.get_account_reference!(account_reference_id)
      else
        nil
      end

    case Map.get(params, "action") do
      "quick_quote" ->
        handle_quick_quote(quote_params, params, socket, account_reference)

      "full_quote" ->
        handle_full_quote(quote_params, params, socket, account_reference)

      _ ->
        handle_regular_quote(quote_params, params, socket, account_reference)
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

  # Handle quick quote request to FreightWare API
  defp handle_quick_quote(quote_params, params, socket, account_reference) do
    items = extract_items_from_params(params)
    shipment_data = build_shipment_data(quote_params, items)

    # Use account reference credentials for API call
    api_opts = build_api_opts(account_reference)

    case TragarApi.quick_quote(shipment_data, api_opts) do
      {:ok, response} ->
        content = build_content_from_params(quote_params, items)

        quick_quote_attrs = %{
          "author" => quote_params["consignor_name"] || "FreightWare API",
          "content" => "Quick Quote: #{content}",
          "status" => "pending",
          "total_amount" => extract_total_amount_from_response(response),
          "consignor_name" => Map.get(quote_params, "consignor_name"),
          "consignee_name" => Map.get(quote_params, "consignee_name"),
          "account_reference_id" => account_reference && account_reference.id
        }

        case Quotes.create_quote(quick_quote_attrs) do
          {:ok, quote} ->
            Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_created, quote})

            socket =
              socket
              |> assign(:show_form, false)
              |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
              |> assign(:items, [])
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
  defp handle_full_quote(quote_params, params, socket, account_reference) do
    items = extract_items_from_params(params)
    quote_data = build_quote_data(quote_params, items)

    # Use account reference credentials for API call
    api_opts = build_api_opts(account_reference)

    case TragarApi.create_quote(quote_data, api_opts) do
      {:ok, response} ->
        content = build_content_from_params(quote_params, items)

        full_quote_attrs =
          Map.merge(quote_params, %{
            "author" => quote_params["consignor_name"] || "FreightWare API",
            "content" => "Full Quote: #{content}",
            "status" => "pending",
            "total_amount" => extract_total_amount_from_response(response),
            "account_reference_id" => account_reference && account_reference.id
          })

        case Quotes.create_quote(full_quote_attrs) do
          {:ok, quote} ->
            Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_created, quote})

            socket =
              socket
              |> assign(:show_form, false)
              |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
              |> assign(:items, [])
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
  defp handle_regular_quote(quote_params, params, socket, account_reference) do
    items = extract_items_from_params(params)
    content = build_content_from_params(quote_params, items)

    quote_attrs =
      Map.merge(quote_params, %{
        "content" => content,
        "author" => quote_params["consignor_name"] || "Unknown",
        "status" => "pending",
        "account_reference_id" => account_reference && account_reference.id
      })

    case Quotes.create_quote(quote_attrs) do
      {:ok, quote} ->
        Phoenix.PubSub.broadcast(TragarCms.PubSub, "quotes", {:quote_created, quote})

        socket =
          socket
          |> assign(:show_form, false)
          |> assign(:form, to_form(Quotes.change_quote(%Quote{})))
          |> assign(:items, [])
          |> put_flash(:info, "Quote created successfully")
          |> load_quotes()
          |> calculate_stats()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
    end
  end

  # Build API options from account reference credentials
  defp build_api_opts(nil), do: []

  defp build_api_opts(account_reference) do
    [
      username: account_reference.api_username,
      password: account_reference.api_password,
      station: account_reference.api_station
    ]
  end

  # Build content description from quote parameters and items
  defp build_content_from_params(quote_params, items) do
    consignor = Map.get(quote_params, "consignor_name", "Unknown")
    consignee = Map.get(quote_params, "consignee_name", "Unknown")
    item_count = length(items)

    if item_count > 0 do
      "#{consignor} to #{consignee} (#{item_count} items)"
    else
      "#{consignor} to #{consignee}"
    end
  end

  # Build shipment data for quick quote API call
  defp build_shipment_data(quote_params, items) do
    first_item = List.first(items) || %{}

    %{
      "consignorSuburb" => Map.get(quote_params, "consignor_suburb", ""),
      "consignorCity" => Map.get(quote_params, "consignor_city", ""),
      "consignorPostalCode" => Map.get(quote_params, "consignor_postal_code", ""),
      "consigneeSuburb" => Map.get(quote_params, "consignee_suburb", ""),
      "consigneeCity" => Map.get(quote_params, "consignee_city", ""),
      "consigneePostalCode" => Map.get(quote_params, "consignee_postal_code", ""),
      "serviceType" => Map.get(quote_params, "service_type", ""),
      "totalQuantity" => calculate_total_quantity(items),
      "totalWeight" => calculate_total_weight(items),
      "length" => parse_decimal(Map.get(first_item, "length", "10")),
      "width" => parse_decimal(Map.get(first_item, "width", "10")),
      "height" => parse_decimal(Map.get(first_item, "height", "10"))
    }
  end

  # Build quote data for full quote API call
  defp build_quote_data(quote_params, items) do
    Map.merge(quote_params, %{
      "total_quantity" => calculate_total_quantity(items),
      "total_weight" => calculate_total_weight(items),
      "items" => format_items_for_api(items)
    })
  end

  defp extract_items_from_params(params) do
    case params["items"] do
      nil ->
        []

      items_map when is_map(items_map) ->
        items_map
        |> Enum.sort_by(fn {key, _value} -> String.to_integer(key) end)
        |> Enum.map(fn {_index, item} ->
          %{
            "description" => item["description"] || "",
            "quantity" => parse_integer(item["quantity"]),
            "weight" => parse_decimal(item["weight"]),
            "length" => parse_decimal(item["length"]),
            "width" => parse_decimal(item["width"]),
            "height" => parse_decimal(item["height"]),
            "unit_value" => parse_decimal(item["unit_value"]),
            "package_type" => item["package_type"] || "",
            "special_handling" => item["special_handling"] || "",
            "special_instructions" => item["special_instructions"] || ""
          }
        end)
        |> Enum.reject(fn item ->
          item["description"] == "" || item["description"] == nil
        end)

      _ ->
        []
    end
  end

  defp format_items_for_api(items) do
    items
    |> Enum.with_index(1)
    |> Enum.map(fn {item, index} ->
      %{
        "line_number" => index,
        "quantity" => item["quantity"],
        "description" => item["description"],
        "weight" => item["weight"],
        "length" => item["length"],
        "width" => item["width"],
        "height" => item["height"],
        "unit_value" => item["unit_value"],
        "package_type" => item["package_type"]
      }
    end)
  end

  defp calculate_total_quantity(items) do
    items
    |> Enum.map(fn item -> item["quantity"] || 0 end)
    |> Enum.sum()
  end

  defp calculate_total_weight(items) do
    items
    |> Enum.map(fn item -> item["weight"] || Decimal.new(0) end)
    |> Enum.reduce(Decimal.new(0), fn weight, acc ->
      case weight do
        %Decimal{} -> Decimal.add(acc, weight)
        _ -> acc
      end
    end)
  end

  # Extract total amount from API response
  defp extract_total_amount_from_response(response) do
    cond do
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
      :error -> 0
    end
  end

  defp parse_integer(value) when is_integer(value), do: value
  defp parse_integer(_), do: 0

  defp parse_decimal(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, _} -> decimal
      :error -> Decimal.new(0)
    end
  rescue
    _ -> Decimal.new(0)
  end

  defp parse_decimal(value) when is_number(value), do: Decimal.new(value)
  defp parse_decimal(_), do: Decimal.new(0)

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

    avg_value =
      if total_quotes > 0 do
        Decimal.div(total_value, total_quotes)
      else
        Decimal.new(0)
      end

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
        float_value = Decimal.to_float(decimal_value)

        :erlang.float_to_binary(float_value, decimals: 2)
        |> then(fn formatted -> "R#{formatted}" end)
    end
  rescue
    _ -> "R0.00"
  end
end
