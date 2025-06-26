defmodule TragarCms.Quotes.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quotes" do
    # Core quote fields
    field :quote_number, :string
    field :quote_obj, :decimal
    field :quote_date, :date
    field :account_reference, :string
    field :shipper_reference, :string
    field :service_type, :string
    field :service_type_description, :string
    field :consignment_type, :string
    field :consignment_type_desc, :string
    field :status_code, :string
    field :status_description, :string
    field :collection_instructions, :string
    field :delivery_instructions, :string
    field :estimated_kilometres, :integer
    field :billable_units, :integer
    field :rate_type, :string
    field :rate_type_description, :string
    field :total_quantity, :integer
    field :total_weight, :decimal

    # Consignor (sender) information
    field :consignor_site, :string
    field :consignor_name, :string
    field :consignor_building, :string
    field :consignor_street, :string
    field :consignor_suburb, :string
    field :consignor_city, :string
    field :consignor_postal_code, :string
    field :consignor_contact_name, :string
    field :consignor_contact_tel, :string

    # Consignee (receiver) information
    field :consignee_site, :string
    field :consignee_name, :string
    field :consignee_building, :string
    field :consignee_street, :string
    field :consignee_suburb, :string
    field :consignee_city, :string
    field :consignee_postal_code, :string
    field :consignee_contact_name, :string
    field :consignee_contact_tel, :string

    # Additional fields
    field :waybill_number, :string
    field :collection_reference, :string
    field :accepted_by, :string
    field :reject_reason, :string
    field :order_number, :string
    field :value_declared, :decimal
    field :charged_amount, :decimal
    field :cash_account_type, :string
    field :paying_party, :string
    field :vehicle_category, :string

    # Quote items as embedded JSON
    field :items, {:array, :map}, default: []

    # Legacy fields for backwards compatibility
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
    |> cast(attrs, [
      :quote_number,
      :quote_obj,
      :quote_date,
      :account_reference,
      :shipper_reference,
      :service_type,
      :service_type_description,
      :consignment_type,
      :consignment_type_desc,
      :status_code,
      :status_description,
      :collection_instructions,
      :delivery_instructions,
      :estimated_kilometres,
      :billable_units,
      :rate_type,
      :rate_type_description,
      :total_quantity,
      :total_weight,
      :consignor_site,
      :consignor_name,
      :consignor_building,
      :consignor_street,
      :consignor_suburb,
      :consignor_city,
      :consignor_postal_code,
      :consignor_contact_name,
      :consignor_contact_tel,
      :consignee_site,
      :consignee_name,
      :consignee_building,
      :consignee_street,
      :consignee_suburb,
      :consignee_city,
      :consignee_postal_code,
      :consignee_contact_name,
      :consignee_contact_tel,
      :waybill_number,
      :collection_reference,
      :accepted_by,
      :reject_reason,
      :order_number,
      :value_declared,
      :charged_amount,
      :cash_account_type,
      :paying_party,
      :vehicle_category,
      :content,
      :author,
      :source,
      :category,
      :status
    ])
    |> validate_required([
      :consignor_name,
      :consignor_building,
      :consignor_street,
      :consignor_suburb,
      :consignor_city,
      :consignor_postal_code,
      :consignor_contact_name,
      :consignor_contact_tel,
      :consignee_name,
      :consignee_building,
      :consignee_street,
      :consignee_suburb,
      :consignee_city,
      :consignee_postal_code,
      :consignee_contact_name,
      :consignee_contact_tel
    ])
    |> validate_length(:quote_number, max: 35)
    |> validate_length(:account_reference, max: 15)
    |> validate_length(:shipper_reference, max: 35)
    |> validate_length(:service_type, max: 10)
    |> validate_length(:consignor_name, max: 70)
    |> validate_length(:consignee_name, max: 70)
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
