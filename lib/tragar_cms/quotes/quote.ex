defmodule TragarCms.Quotes.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "quotes" do
    field :author, :string
    field :content, :string
    field :status, :string
    field :total_amount, :decimal

    # Core quote fields (these exist in database)
    field :quote_number, :string
    field :quote_obj, :decimal
    field :quote_date, :date
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

    # Consignor fields (these exist in database)
    field :consignor_site, :string
    field :consignor_name, :string
    field :consignor_building, :string
    field :consignor_street, :string
    field :consignor_suburb, :string
    field :consignor_city, :string
    field :consignor_postal_code, :string
    field :consignor_contact_name, :string
    field :consignor_contact_tel, :string

    # Consignee fields (these exist in database)
    field :consignee_site, :string
    field :consignee_name, :string
    field :consignee_building, :string
    field :consignee_street, :string
    field :consignee_suburb, :string
    field :consignee_city, :string
    field :consignee_postal_code, :string
    field :consignee_contact_name, :string
    field :consignee_contact_tel, :string

    # Additional fields (these exist in database)
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

    # Relationships
    belongs_to :account_reference, TragarCms.Accounts.AccountReference

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [
      :author,
      :content,
      :status,
      :total_amount,
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
      :account_reference_id
    ])
    |> validate_required([:content, :status])
    |> validate_inclusion(:status, ["pending", "accepted", "rejected"])
  end

  def get_stats(quotes) do
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

    %{
      total_quotes: total_quotes,
      pending_quotes: pending_quotes,
      accepted_quotes: accepted_quotes,
      rejected_quotes: rejected_quotes,
      total_value: total_value,
      avg_value: avg_value,
      pending_value: pending_value
    }
  end
end
