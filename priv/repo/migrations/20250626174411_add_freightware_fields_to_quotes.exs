defmodule TragarCms.Repo.Migrations.AddFreightwareFieldsToQuotes do
  use Ecto.Migration

  def change do
    alter table(:quotes) do
      # Core quote fields
      add :quote_number, :string, size: 35
      add :quote_obj, :decimal
      add :quote_date, :date
      add :account_reference, :string, size: 15
      add :shipper_reference, :string, size: 35
      add :service_type, :string, size: 10
      add :service_type_description, :string, size: 35
      add :consignment_type, :string, size: 10
      add :consignment_type_desc, :string, size: 35
      add :status_code, :string, size: 3
      add :status_description, :string, size: 35
      add :collection_instructions, :string, size: 500
      add :delivery_instructions, :string, size: 500
      add :estimated_kilometres, :integer
      add :billable_units, :integer
      add :rate_type, :string, size: 10
      add :rate_type_description, :string, size: 35
      add :total_quantity, :integer
      add :total_weight, :decimal

      # Consignor (sender) information
      add :consignor_site, :string, size: 15
      add :consignor_name, :string, size: 70
      add :consignor_building, :string, size: 500
      add :consignor_street, :string, size: 500
      add :consignor_suburb, :string, size: 500
      add :consignor_city, :string, size: 500
      add :consignor_postal_code, :string, size: 30
      add :consignor_contact_name, :string, size: 70
      add :consignor_contact_tel, :string, size: 15

      # Consignee (receiver) information
      add :consignee_site, :string, size: 15
      add :consignee_name, :string, size: 70
      add :consignee_building, :string, size: 500
      add :consignee_street, :string, size: 500
      add :consignee_suburb, :string, size: 500
      add :consignee_city, :string, size: 500
      add :consignee_postal_code, :string, size: 30
      add :consignee_contact_name, :string, size: 70
      add :consignee_contact_tel, :string, size: 15

      # Additional fields
      add :waybill_number, :string, size: 35
      add :collection_reference, :string, size: 15
      add :accepted_by, :string, size: 70
      add :reject_reason, :string, size: 500
      add :order_number, :string, size: 15
      add :value_declared, :decimal
      add :charged_amount, :decimal
      add :cash_account_type, :string, size: 15
      add :paying_party, :string, size: 15
      add :vehicle_category, :string, size: 10
    end

    # Add indexes for performance
    create index(:quotes, [:quote_number])
    create index(:quotes, [:quote_date])
    create index(:quotes, [:status_code])
    create index(:quotes, [:consignor_name])
    create index(:quotes, [:consignee_name])
  end
end
