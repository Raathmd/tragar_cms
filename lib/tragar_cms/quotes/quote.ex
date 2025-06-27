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

    # Quote metadata fields
    field :quote_type, :string
    field :quote_number, :string
    field :quote_obj, :string
    field :quote_date, :string
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
    field :billable_units, :decimal
    field :rate_type, :string
    field :rate_type_description, :string
    field :total_quantity, :integer
    field :total_weight, :decimal

    # Consignor fields
    field :consignor_site, :string
    field :consignor_name, :string
    field :consignor_building, :string
    field :consignor_street, :string
    field :consignor_suburb, :string
    field :consignor_city, :string
    field :consignor_postal_code, :string
    field :consignor_contact_name, :string
    field :consignor_contact_tel, :string

    # Consignee fields
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
    field :api_response, :string

    # Relationships
    belongs_to :organization, TragarCms.Accounts.Organization
    belongs_to :branch, TragarCms.Accounts.Branch
    belongs_to :created_by_user, TragarCms.Accounts.User

    # Embedded items
    embeds_many :items, Item do
      field :line_number, :integer
      field :quantity, :integer
      field :product_code, :string
      field :description, :string
      field :weight, :decimal
      field :length, :decimal
      field :width, :decimal
      field :height, :decimal
      field :volumetric_weight, :decimal
      field :rate_type, :string
      field :unit_value, :decimal
      field :package_type, :string
      field :special_handling, :string
      field :special_instructions, :string
    end

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
      :quote_type,
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
      :api_response,
      :organization_id,
      :branch_id,
      :created_by_user_id
    ])
    |> cast_embed(:items, with: &item_changeset/2)
    |> validate_required([:content, :status])
    |> validate_inclusion(:status, ["pending", "accepted", "rejected"])
  end

  defp item_changeset(item, attrs) do
    item
    |> cast(attrs, [
      :line_number,
      :quantity,
      :product_code,
      :description,
      :weight,
      :length,
      :width,
      :height,
      :volumetric_weight,
      :rate_type,
      :unit_value,
      :package_type,
      :special_handling,
      :special_instructions
    ])
    |> validate_required([:quantity, :weight])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:weight, greater_than: 0)
  end
end
