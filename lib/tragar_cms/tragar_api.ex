defmodule TragarCms.TragarApi do
  @moduledoc """
  Client for interacting with the Tragar API to fetch quotes.
  """

  require Logger

  # For now, we'll use a mock API endpoint
  # In production, this would be the real Tragar API URL
  @base_url "https://api.quotable.io"

  @doc """
  Fetches quotes from the Tragar API.
  Returns a list of quote maps or an error tuple.
  """
  def fetch_quotes(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    case Req.get("#{@base_url}/quotes", params: [limit: limit]) do
      {:ok, %{status: 200, body: %{"results" => quotes}}} ->
        formatted_quotes = Enum.map(quotes, &format_quote/1)
        {:ok, formatted_quotes}

      {:ok, %{status: status}} ->
        Logger.error("Tragar API returned status: #{status}")
        {:error, "API returned status #{status}"}

      {:error, reason} ->
        Logger.error("Failed to fetch from Tragar API: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  @doc """
  Fetches a single random quote from the API.
  """
  def fetch_random_quote do
    case Req.get("#{@base_url}/random") do
      {:ok, %{status: 200, body: quote}} ->
        {:ok, format_quote(quote)}

      {:ok, %{status: status}} ->
        Logger.error("Tragar API returned status: #{status}")
        {:error, "API returned status #{status}"}

      {:error, reason} ->
        Logger.error("Failed to fetch random quote: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}
    end
  end

  @doc """
  Gets API status and connection health.
  """
  def health_check do
    case Req.get("#{@base_url}/random") do
      {:ok, %{status: 200}} ->
        {:ok, "Connected"}

      {:ok, %{status: status}} ->
        {:error, "API returned status #{status}"}

      {:error, reason} ->
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  # Private function to format API quotes to match our schema
  defp format_quote(api_quote) do
    %{
      "content" => Map.get(api_quote, "content", ""),
      "author" => Map.get(api_quote, "author", "Unknown"),
      "source" => "Tragar API",
      "category" => format_tags(Map.get(api_quote, "tags", [])),
      "status" => "pending"
    }
  end

  defp format_tags([]), do: "General"
  defp format_tags([tag | _]), do: String.capitalize(tag)
end
