defmodule TragarCms.Quotes.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quotes" do
    field :content, :string
    field :author, :string
    field :source, :string
    field :category, :string
    field :status, :string, default: "pending"

    timestamps()
  end

  @doc false
  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [:content, :author, :source, :category, :status])
    |> validate_required([:content, :author])
    |> validate_length(:content, min: 10, max: 1000)
    |> validate_length(:author, min: 2, max: 100)
    |> validate_length(:source, max: 200)
    |> validate_length(:category, max: 50)
    |> validate_inclusion(:status, ["pending", "published", "archived"])
  end

  @doc """
  Returns quote statistics for dashboard cards
  """
  def get_stats(quotes) do
    total = length(quotes)
    published = Enum.count(quotes, &(&1.status == "published"))
    pending = Enum.count(quotes, &(&1.status == "pending"))
    authors = quotes |> Enum.map(& &1.author) |> Enum.uniq() |> length()

    %{
      total: total,
      published: published,
      pending: pending,
      authors: authors
    }
  end
end
