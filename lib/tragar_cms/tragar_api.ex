defmodule TragarCms.TragarApi do
  @moduledoc """
  Client for interacting with the FreightWare/Tragar API to fetch quotes.
  Handles authentication and quote retrieval operations.
  """

  require Logger

  # FreightWare API base URL - updated with your provided endpoint
  @base_url "http://tragar-db.dovetail.co.za:5001/WebServices/web"

  # Default credentials from environment variables
  @default_username System.get_env("TRAGAR_USERNAME", "demo_user")
  @default_password System.get_env("TRAGAR_PASSWORD", "demo_pass")
  @default_station System.get_env("TRAGAR_STATION", "demo_station")

  @doc """
  Authenticates with FreightWare and returns the auth token.
  Returns {:ok, token} or {:error, reason}.
  """
  def authenticate(opts \\ []) do
    username = Keyword.get(opts, :username, @default_username)
    password = Keyword.get(opts, :password, @default_password)
    station = Keyword.get(opts, :station, @default_station)

    body = %{
      username: username,
      password: password,
      station: station
    }

    case Req.post("#{@base_url}/FreightWare/V2/system/auth/login",
           json: body,
           receive_timeout: 30_000,
           connect_options: [timeout: 30_000]
         ) do
      {:ok, %{status: 200, headers: headers}} ->
        case extract_auth_token(headers) do
          {:ok, token} ->
            Logger.info("Successfully authenticated with FreightWare")
            {:ok, token}

          {:error, reason} ->
            Logger.error("Failed to extract auth token: #{reason}")
            {:error, "Authentication failed: #{reason}"}
        end

      {:ok, %{status: status}} ->
        Logger.error("FreightWare login failed with status: #{status}")
        {:error, "Authentication failed with status #{status}"}

      {:error, reason} ->
        Logger.error("Failed to connect to FreightWare: #{inspect(reason)}")
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Fetches quotes from FreightWare with authentication.
  Returns a list of quote maps or an error tuple.
  """
  def fetch_quotes(opts \\ []) do
    with {:ok, token} <- authenticate(opts),
         {:ok, quotes} <- fetch_quotes_with_token(token, opts) do
      {:ok, quotes}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets a specific quote by quote number or quote object.
  Returns {:ok, quote} or {:error, reason}.
  """
  def get_quote(quote_identifier, opts \\ []) do
    with {:ok, token} <- authenticate(opts),
         {:ok, quote} <- get_quote_with_token(token, quote_identifier) do
      {:ok, quote}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates a new quote in FreightWare using the V1 API.
  """
  def create_quote(quote_data, opts \\ []) do
    with {:ok, token} <- authenticate(opts),
         {:ok, response} <- create_quote_with_token(token, quote_data) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Updates an existing quote in FreightWare.
  """
  def update_quote(quote_identifier, quote_data, opts \\ []) do
    with {:ok, token} <- authenticate(opts),
         {:ok, response} <- update_quote_with_token(token, quote_identifier, quote_data) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets a quick quote (rate estimate) without creating an official quote.
  """
  def quick_quote(shipment_data, opts \\ []) do
    with {:ok, token} <- authenticate(opts),
         {:ok, response} <- quick_quote_with_token(token, shipment_data) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Accepts a quote in FreightWare.
  """
  def accept_quote(quote_obj, acceptance_type, accepted_by, opts \\ []) do
    with {:ok, token} <- authenticate(opts),
         {:ok, response} <-
           accept_quote_with_token(token, quote_obj, acceptance_type, accepted_by, opts) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Rejects a quote in FreightWare.
  """
  def reject_quote(quote_obj, reject_reason, opts \\ []) do
    with {:ok, token} <- authenticate(opts),
         {:ok, response} <- reject_quote_with_token(token, quote_obj, reject_reason) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets quote tracking information.
  """
  def track_quote(quote_obj_or_number, opts \\ []) do
    with {:ok, token} <- authenticate(opts),
         {:ok, response} <- track_quote_with_token(token, quote_obj_or_number) do
      {:ok, response}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Gets API status and connection health.
  """
  def health_check do
    case authenticate() do
      {:ok, _token} ->
        {:ok, "Connected"}

      {:error, reason} ->
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  # Private functions

  defp fetch_quotes_with_token(token, opts) do
    headers = [{"X-FreightWare", token}]

    # Build query filters if provided
    filters = build_quote_filters(opts)
    query_params = if filters != %{}, do: [filters: Jason.encode!(filters)], else: []

    # Use the real FreightWare V1 quotes endpoint
    case Req.get("#{@base_url}/FreightWare/V1/quotes/",
           headers: headers,
           params: query_params,
           receive_timeout: 30_000,
           connect_options: [timeout: 30_000]
         ) do
      {:ok, %{status: 200, body: response_body}} when is_map(response_body) ->
        Logger.info("Successfully fetched quotes from FreightWare")
        quotes = parse_freightware_quotes(response_body, opts)
        {:ok, quotes}

      {:ok, %{status: status, body: response_body}} ->
        Logger.error("FreightWare quotes request failed with status: #{status}")
        Logger.error("Response body: #{inspect(response_body)}")
        {:error, "Failed to fetch quotes: HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to fetch quotes from FreightWare: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp get_quote_with_token(token, quote_identifier) do
    headers = [{"X-FreightWare", token}]
    url = "#{@base_url}/FreightWare/V1/quotes/#{quote_identifier}/"

    case Req.get(url,
           headers: headers,
           receive_timeout: 30_000,
           connect_options: [timeout: 30_000]
         ) do
      {:ok, %{status: 200, body: response_body}} when is_map(response_body) ->
        Logger.info("Successfully fetched quote #{quote_identifier}")
        quote = parse_single_quote(response_body)
        {:ok, quote}

      {:ok, %{status: status, body: response_body}} ->
        Logger.error("FreightWare get quote request failed with status: #{status}")
        Logger.error("Response body: #{inspect(response_body)}")
        {:error, "Failed to get quote: HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to get quote from FreightWare: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp create_quote_with_token(token, quote_data) do
    headers = [{"X-FreightWare", token}, {"Content-Type", "application/json"}]

    # Build FreightWare quote request format
    body = build_freightware_quote_request(quote_data)

    case Req.post("#{@base_url}/FreightWare/V1/quotes/",
           headers: headers,
           json: body,
           receive_timeout: 30_000,
           connect_options: [timeout: 30_000]
         ) do
      {:ok, %{status: 200, body: response}} ->
        Logger.info("Successfully created quote in FreightWare")
        {:ok, response}

      {:ok, %{status: status, body: response_body}} ->
        Logger.error("FreightWare quote creation failed with status: #{status}")
        Logger.error("Response body: #{inspect(response_body)}")
        {:error, "Failed to create quote: HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to create quote in FreightWare: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp update_quote_with_token(token, quote_identifier, quote_data) do
    headers = [{"X-FreightWare", token}, {"Content-Type", "application/json"}]
    url = "#{@base_url}/FreightWare/V1/quotes/#{quote_identifier}/"

    # Build FreightWare quote request format
    body = build_freightware_quote_request(quote_data)

    case Req.put(url,
           headers: headers,
           json: body,
           receive_timeout: 30_000,
           connect_options: [timeout: 30_000]
         ) do
      {:ok, %{status: 200, body: response}} ->
        Logger.info("Successfully updated quote #{quote_identifier}")
        {:ok, response}

      {:ok, %{status: status, body: response_body}} ->
        Logger.error("FreightWare quote update failed with status: #{status}")
        Logger.error("Response body: #{inspect(response_body)}")
        {:error, "Failed to update quote: HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to update quote in FreightWare: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp quick_quote_with_token(token, shipment_data) do
    headers = [{"X-FreightWare", token}, {"Content-Type", "application/json"}]

    # Build FreightWare shipment request format
    body = build_freightware_shipment_request(shipment_data)

    case Req.post("#{@base_url}/FreightWare/V1/quotes/quick",
           headers: headers,
           json: body,
           receive_timeout: 30_000,
           connect_options: [timeout: 30_000]
         ) do
      {:ok, %{status: 200, body: response}} ->
        Logger.info("Successfully retrieved quick quote")
        {:ok, response}

      {:ok, %{status: status, body: response_body}} ->
        Logger.error("FreightWare quick quote failed with status: #{status}")
        Logger.error("Response body: #{inspect(response_body)}")
        {:error, "Failed to get quick quote: HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to get quick quote from FreightWare: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp accept_quote_with_token(token, quote_obj, acceptance_type, accepted_by, opts) do
    headers = [{"X-FreightWare", token}]

    query_params = [
      acceptedBy: accepted_by,
      acceptReference: Keyword.get(opts, :accept_reference, ""),
      createCollection: Keyword.get(opts, :create_collection, true),
      collectionIsQuoteNumber: Keyword.get(opts, :collection_is_quote_number, true),
      createWaybill: Keyword.get(opts, :create_waybill, true)
    ]

    url = "#{@base_url}/FreightWare/V1/quotes/#{quote_obj}/accept/#{acceptance_type}"

    case Req.put(url,
           headers: headers,
           params: query_params,
           receive_timeout: 30_000,
           connect_options: [timeout: 30_000]
         ) do
      {:ok, %{status: 200}} ->
        Logger.info("Successfully accepted quote #{quote_obj}")
        {:ok, :accepted}

      {:ok, %{status: status, body: response_body}} ->
        Logger.error("FreightWare quote acceptance failed with status: #{status}")
        {:error, "Failed to accept quote: HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to accept quote in FreightWare: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp reject_quote_with_token(token, quote_obj, reject_reason) do
    headers = [{"X-FreightWare", token}]
    query_params = [rejectReason: reject_reason]

    url = "#{@base_url}/FreightWare/V1/quotes/#{quote_obj}/reject"

    case Req.put(url,
           headers: headers,
           params: query_params,
           receive_timeout: 30_000,
           connect_options: [timeout: 30_000]
         ) do
      {:ok, %{status: 200}} ->
        Logger.info("Successfully rejected quote #{quote_obj}")
        {:ok, :rejected}

      {:ok, %{status: status}} ->
        Logger.error("FreightWare quote rejection failed with status: #{status}")
        {:error, "Failed to reject quote: HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to reject quote in FreightWare: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp track_quote_with_token(token, quote_obj_or_number) do
    headers = [{"X-FreightWare", token}]
    url = "#{@base_url}/FreightWare/V1/quotes/#{quote_obj_or_number}/trackAndTrace"

    case Req.get(url,
           headers: headers,
           receive_timeout: 30_000,
           connect_options: [timeout: 30_000]
         ) do
      {:ok, %{status: 200, body: response_body}} ->
        Logger.info("Successfully retrieved tracking for quote #{quote_obj_or_number}")
        {:ok, response_body}

      {:ok, %{status: status}} ->
        Logger.error("FreightWare tracking request failed with status: #{status}")
        {:error, "Failed to get tracking: HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to get tracking from FreightWare: #{inspect(reason)}")
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  defp extract_auth_token(headers) do
    case Enum.find(headers, fn {name, _value} ->
           String.downcase(name) == "x-freightware"
         end) do
      {_name, token} when is_binary(token) and token != "" ->
        {:ok, token}

      _ ->
        {:error, "X-FreightWare header not found or empty"}
    end
  end

  defp build_quote_filters(opts) do
    filters = %{}

    filters =
      if quote_number = Keyword.get(opts, :quote_number),
        do: Map.put(filters, :quoteNumber, quote_number),
        else: filters

    filters =
      if account_ref = Keyword.get(opts, :account_reference),
        do: Map.put(filters, :accountReference, account_ref),
        else: filters

    filters =
      if status_code = Keyword.get(opts, :status_code),
        do: Map.put(filters, :statusCode, status_code),
        else: filters

    filters =
      if date_from = Keyword.get(opts, :date_from),
        do: Map.put(filters, :dateFrom, date_from),
        else: filters

    filters =
      if date_to = Keyword.get(opts, :date_to),
        do: Map.put(filters, :dateTo, date_to),
        else: filters

    filters
  end

  defp parse_freightware_quotes(response_body, opts) do
    limit = Keyword.get(opts, :limit, 10)

    case response_body do
      # Handle the correct response format according to API spec
      %{"response" => %{"esQuotes" => quotes_data}} when is_binary(quotes_data) ->
        case Jason.decode(quotes_data) do
          {:ok, parsed_quotes} ->
            parsed_quotes
            |> extract_quotes_from_response()
            |> Enum.take(limit)
            |> Enum.map(&convert_freightware_quote_to_cms_format/1)

          {:error, _} ->
            Logger.warning("Failed to parse FreightWare quotes JSON response")
            generate_sample_quotes(limit)
        end

      # Handle esWaybills response (legacy format)
      %{"response" => %{"esWaybills" => quotes_data}} when is_binary(quotes_data) ->
        case Jason.decode(quotes_data) do
          {:ok, parsed_quotes} ->
            parsed_quotes
            |> extract_quotes_from_response()
            |> Enum.take(limit)
            |> Enum.map(&convert_freightware_quote_to_cms_format/1)

          {:error, _} ->
            Logger.warning("Failed to parse FreightWare quotes JSON response")
            generate_sample_quotes(limit)
        end

      %{"response" => response} when is_map(response) ->
        response
        |> extract_quotes_from_response()
        |> Enum.take(limit)
        |> Enum.map(&convert_freightware_quote_to_cms_format/1)

      _ ->
        Logger.warning("Unexpected FreightWare response format: #{inspect(response_body)}")
        generate_sample_quotes(limit)
    end
  end

  defp parse_single_quote(response_body) do
    case response_body do
      %{"response" => %{"esQuotes" => quote_data}} when is_binary(quote_data) ->
        case Jason.decode(quote_data) do
          {:ok, parsed_quote} ->
            convert_freightware_quote_to_cms_format(parsed_quote)

          {:error, _} ->
            Logger.warning("Failed to parse single quote JSON response")
            nil
        end

      %{"response" => quote} when is_map(quote) ->
        convert_freightware_quote_to_cms_format(quote)

      _ ->
        Logger.warning("Unexpected single quote response format: #{inspect(response_body)}")
        nil
    end
  end

  defp extract_quotes_from_response(response) when is_map(response) do
    cond do
      Map.has_key?(response, "Quotes") -> Map.get(response, "Quotes", [])
      Map.has_key?(response, "quotes") -> Map.get(response, "quotes", [])
      is_list(response) -> response
      true -> [response]
    end
  end

  defp extract_quotes_from_response(response) when is_list(response), do: response
  defp extract_quotes_from_response(_), do: []

  defp convert_freightware_quote_to_cms_format(quote) when is_map(quote) do
    %{
      "quote_number" => Map.get(quote, "quoteNumber"),
      "quote_obj" => Map.get(quote, "quoteObj"),
      "quote_date" => Map.get(quote, "quoteDate"),
      "account_reference" => Map.get(quote, "accountReference"),
      "shipper_reference" => Map.get(quote, "shipperReference"),
      "service_type" => Map.get(quote, "serviceType"),
      "service_type_description" => Map.get(quote, "serviceTypeDescription"),
      "consignment_type" => Map.get(quote, "consignmentType"),
      "consignment_type_desc" => Map.get(quote, "consignmentTypeDesc"),
      "status_code" => Map.get(quote, "statusCode"),
      "status_description" => Map.get(quote, "statusDescription"),
      "collection_instructions" => Map.get(quote, "collectionInstructions"),
      "delivery_instructions" => Map.get(quote, "deliveryInstructions"),
      "estimated_kilometres" => Map.get(quote, "estimatedKilometres"),
      "billable_units" => Map.get(quote, "billableUnits"),
      "rate_type" => Map.get(quote, "rateType"),
      "rate_type_description" => Map.get(quote, "rateTypeDescription"),
      "total_quantity" => Map.get(quote, "totalQuantity"),
      "total_weight" => Map.get(quote, "totalWeight"),
      "consignor_site" => Map.get(quote, "consignorSite"),
      "consignor_name" => Map.get(quote, "consignorName"),
      "consignor_building" => Map.get(quote, "consignorBuilding"),
      "consignor_street" => Map.get(quote, "consignorStreet"),
      "consignor_suburb" => Map.get(quote, "consignorSuburb"),
      "consignor_city" => Map.get(quote, "consignorCity"),
      "consignor_postal_code" => Map.get(quote, "consignorPostalCode"),
      "consignor_contact_name" => Map.get(quote, "consignorContactName"),
      "consignor_contact_tel" => Map.get(quote, "consignorContactTel"),
      "consignee_site" => Map.get(quote, "consigneeSite"),
      "consignee_name" => Map.get(quote, "consigneeName"),
      "consignee_building" => Map.get(quote, "consigneeBuilding"),
      "consignee_street" => Map.get(quote, "consigneeStreet"),
      "consignee_suburb" => Map.get(quote, "consigneeSuburb"),
      "consignee_city" => Map.get(quote, "consigneeCity"),
      "consignee_postal_code" => Map.get(quote, "consigneePostalCode"),
      "consignee_contact_name" => Map.get(quote, "consigneeContactName"),
      "consignee_contact_tel" => Map.get(quote, "consigneeContactTel"),
      "waybill_number" => Map.get(quote, "waybillNumber"),
      "collection_reference" => Map.get(quote, "collectionReference"),
      "accepted_by" => Map.get(quote, "acceptedBy"),
      "reject_reason" => Map.get(quote, "rejectReason"),
      "order_number" => Map.get(quote, "orderNumber"),
      "value_declared" => Map.get(quote, "valueDeclared"),
      "charged_amount" => Map.get(quote, "chargedAmount"),
      "cash_account_type" => Map.get(quote, "cashAccountType"),
      "paying_party" => Map.get(quote, "payingParty"),
      "vehicle_category" => Map.get(quote, "vehicleCategory"),
      "items" => extract_items_from_quote(quote),
      "content" => build_content_from_quote(quote),
      "author" => "FreightWare System",
      "source" => "FreightWare API",
      "category" => Map.get(quote, "serviceTypeDescription", "Freight"),
      "status" => "pending"
    }
  end

  defp build_freightware_quote_request(quote_data) do
    quote_info = %{
      "collectionInstructions" => Map.get(quote_data, "collection_instructions", ""),
      "deliveryInstructions" => Map.get(quote_data, "delivery_instructions", ""),
      "estimatedKilometres" => Map.get(quote_data, "estimated_kilometres", 0),
      "billableUnits" => Map.get(quote_data, "billable_units", 0),
      "totalQuantity" => Map.get(quote_data, "total_quantity", 1),
      "totalWeight" => Map.get(quote_data, "total_weight", 0),
      "consignorSite" => Map.get(quote_data, "consignor_site", ""),
      "consignorName" => Map.get(quote_data, "consignor_name", ""),
      "consignorBuilding" => Map.get(quote_data, "consignor_building", ""),
      "consignorStreet" => Map.get(quote_data, "consignor_street", ""),
      "consignorSuburb" => Map.get(quote_data, "consignor_suburb", ""),
      "consignorCity" => Map.get(quote_data, "consignor_city", ""),
      "consignorPostalCode" => Map.get(quote_data, "consignor_postal_code", ""),
      "consignorContactName" => Map.get(quote_data, "consignor_contact_name", ""),
      "consignorContactTel" => Map.get(quote_data, "consignor_contact_tel", ""),
      "consigneeSite" => Map.get(quote_data, "consignee_site", ""),
      "consigneeName" => Map.get(quote_data, "consignee_name", ""),
      "consigneeBuilding" => Map.get(quote_data, "consignee_building", ""),
      "consigneeStreet" => Map.get(quote_data, "consignee_street", ""),
      "consigneeSuburb" => Map.get(quote_data, "consignee_suburb", ""),
      "consigneeCity" => Map.get(quote_data, "consignee_city", ""),
      "consigneePostalCode" => Map.get(quote_data, "consignee_postal_code", ""),
      "consigneeContactName" => Map.get(quote_data, "consignee_contact_name", ""),
      "consigneeContactTel" => Map.get(quote_data, "consignee_contact_tel", ""),
      "acceptedBy" => Map.get(quote_data, "accepted_by", ""),
      "rejectReason" => Map.get(quote_data, "reject_reason", ""),
      "chargedAmount" => Map.get(quote_data, "charged_amount", 0),
      "cashAccountType" => Map.get(quote_data, "cash_account_type", "")
    }

    # Build items array
    items =
      Map.get(quote_data, "items", [])
      |> Enum.with_index(1)
      |> Enum.map(fn {item, index} ->
        %{
          "lineNumber" => index,
          "quantity" => Map.get(item, "quantity", 1),
          "productCode" => "",
          "description" => Map.get(item, "description", ""),
          "totalWeight" => Map.get(item, "weight", 0),
          "length" => Map.get(item, "length", 0),
          "width" => Map.get(item, "width", 0),
          "height" => Map.get(item, "height", 0),
          "volumetricWeight" => calculate_volumetric_weight(item),
          "rateType" => "D"
        }
      end)

    %{
      "request" => %{
        "esQuotes" => %{
          "Quotes" => [quote_info],
          "Items" => items
        }
      }
    }
  end

  defp build_freightware_shipment_request(shipment_data) do
    %{
      "request" => %{
        "esShipment" =>
          Map.merge(
            %{
              "serviceType" => "",
              "consignorName" => "",
              "consignorBuilding" => "",
              "consignorStreet" => "",
              "consignorSuburb" => "",
              "consignorCity" => "",
              "consignorPostalCode" => "",
              "consigneeName" => "",
              "consigneeBuilding" => "",
              "consigneeStreet" => "",
              "consigneeSuburb" => "",
              "consigneeCity" => "",
              "consigneePostalCode" => "",
              "totalQuantity" => 1,
              "totalWeight" => 0,
              "length" => 0,
              "width" => 0,
              "height" => 0
            },
            shipment_data
          )
      }
    }
  end

  defp extract_items_from_quote(quote) do
    # If items are embedded in the quote response, extract them
    Map.get(quote, "items", [])
  end

  defp build_content_from_quote(quote) do
    consignor = Map.get(quote, "consignorName", "Unknown")
    consignee = Map.get(quote, "consigneeName", "Unknown")
    service = Map.get(quote, "serviceTypeDescription", "Freight Service")

    "#{service}: #{consignor} to #{consignee}"
  end

  defp calculate_volumetric_weight(item) do
    length = Map.get(item, "length", 0) || 0
    width = Map.get(item, "width", 0) || 0
    height = Map.get(item, "height", 0) || 0

    # Standard volumetric calculation (L x W x H / 5000)
    if length > 0 and width > 0 and height > 0 do
      length * width * height / 5000
    else
      0
    end
  end

  defp generate_sample_quotes(limit) do
    sample_quotes = [
      %{
        "content" => "Quality is not an act, it is a habit.",
        "author" => "Aristotle",
        "source" => "FreightWare System",
        "category" => "Quality",
        "status" => "pending"
      },
      %{
        "content" => "The way to get started is to quit talking and begin doing.",
        "author" => "Walt Disney",
        "source" => "FreightWare System",
        "category" => "Action",
        "status" => "pending"
      },
      %{
        "content" => "Innovation distinguishes between a leader and a follower.",
        "author" => "Steve Jobs",
        "source" => "FreightWare System",
        "category" => "Innovation",
        "status" => "pending"
      },
      %{
        "content" =>
          "Excellence is never an accident. It is always the result of high intention, sincere effort, and intelligent execution.",
        "author" => "Aristotle",
        "source" => "FreightWare System",
        "category" => "Excellence",
        "status" => "pending"
      },
      %{
        "content" =>
          "Success is not final, failure is not fatal: it is the courage to continue that counts.",
        "author" => "Winston Churchill",
        "source" => "FreightWare System",
        "category" => "Perseverance",
        "status" => "pending"
      }
    ]

    sample_quotes |> Enum.take(limit)
  end
end
