defmodule TragarCms.Repo.Migrations.AddMissingQuoteFields do
  use Ecto.Migration

  def change do
    alter table(:quotes) do
      # Quote metadata fields
      add :quote_type, :string
      add :quote_number, :string
      add :quote_obj, :string
      add :quote_date, :string
      add :account_reference, :string
      add :shipper_reference, :string
      add :service_type, :string
      add :service_type_description, :string
      add :consignment_type, :string
      add :consignment_type_desc, :string
      add :status_code, :string
      add :status_description, :string
      add :collection_instructions, :string
      add :delivery_instructions, :string
      add :estimated_kilometres, :integer
      add :billable_units, :decimal
      add :rate_type, :string
      add :rate_type_description, :string
      add :total_quantity, :integer
      add :total_weight, :decimal

      # Consignor fields
      add :consignor_site, :string
      add :consignor_name, :string
      add :consignor_building, :string
      add :consignor_street, :string
      add :consignor_suburb, :string
      add :consignor_city, :string
      add :consignor_postal_code, :string
      add :consignor_contact_name, :string
      add :consignor_contact_tel, :string

      # Consignee fields
      add :consignee_site, :string
      add :consignee_name, :string
      add :consignee_building, :string
      add :consignee_street, :string
      add :consignee_suburb, :string
      add :consignee_city, :string
      add :consignee_postal_code, :string
      add :consignee_contact_name, :string
      add :consignee_contact_tel, :string

      # Additional fields
      add :waybill_number, :string
      add :collection_reference, :string
      add :accepted_by, :string
      add :reject_reason, :string
      add :order_number, :string
      add :value_declared, :decimal
      add :charged_amount, :decimal
      add :cash_account_type, :string
      add :paying_party, :string
      add :vehicle_category, :string
      add :api_response, :string

      # Relationships
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all)
      add :branch_id, references(:branches, type: :binary_id, on_delete: :nilify_all)
      add :created_by_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      # Embedded items as JSON
      add :items, :text
    end

    create index(:quotes, [:organization_id])
    create index(:quotes, [:branch_id])
    create index(:quotes, [:created_by_user_id])
    create index(:quotes, [:quote_number])
    create index(:quotes, [:quote_obj])
    create index(:quotes, [:status])
    create index(:quotes, [:quote_type])
  end
end
