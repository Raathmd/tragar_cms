defmodule TragarCms.Repo.Migrations.AddRemainingQuoteFields do
  use Ecto.Migration

  def change do
    alter table(:quotes) do
      # Essential quote fields for the form
      add :quote_type, :string
      add :service_type, :string

      # Consignor fields
      add :consignor_name, :string
      add :consignor_contact_name, :string
      add :consignor_contact_tel, :string
      add :consignor_building, :string
      add :consignor_street, :string
      add :consignor_suburb, :string
      add :consignor_city, :string
      add :consignor_postal_code, :string

      # Consignee fields
      add :consignee_name, :string
      add :consignee_contact_name, :string
      add :consignee_contact_tel, :string
      add :consignee_building, :string
      add :consignee_street, :string
      add :consignee_suburb, :string
      add :consignee_city, :string
      add :consignee_postal_code, :string

      # Additional essential fields
      add :shipper_reference, :string
      add :value_declared, :decimal
      add :collection_instructions, :text
      add :delivery_instructions, :text
    end
  end
end
