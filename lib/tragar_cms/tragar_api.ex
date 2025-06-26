defmodule TragarCms.TragarApi do
  @moduledoc """
  Client for interacting with the FreightWare/Tragar API to fetch quotes.
  Handles authentication and quote retrieval operations.
  """

  require Logger

  # FreightWare API base URL - update this to your actual FreightWare server
  @base_url "http://tragar-db.dovetail.co.za:5001/WebServices/web"

  # Default credentials - these should be moved to config in production
  @default_username "your_username"
  @default_password "your_password"
  @default_station "your_station"

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
  Fetches a single random quote (simulated for FreightWare).
  In practice, this would call a specific FreightWare endpoint.
  """
  def fetch_random_quote(opts \\ []) do
    case fetch_quotes(Keyword.put(opts, :limit, 1)) do
      {:ok, [quote | _]} -> {:ok, quote}
      {:ok, []} -> {:error, "No quotes available"}
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
    limit = Keyword.get(opts, :limit, 10)

    # This is a placeholder endpoint - update with actual FreightWare quote endpoint
    _headers = [{"Authorization", "Bearer #{token}"}]

    # For now, we'll simulate quotes since we don't have the actual quote endpoint
    # In production, this would be something like:
    # case Req.get("#{@base_url}/FreightWare/V1/quotes", headers: headers, params: [limit: limit]) do

    Logger.info("Simulating quote fetch with FreightWare token")

    # Generate sample quotes for demonstration
    quotes = generate_sample_quotes(limit)
    {:ok, quotes}
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
