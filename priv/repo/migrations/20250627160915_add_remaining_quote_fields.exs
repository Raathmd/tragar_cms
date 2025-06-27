defmodule TragarCms.Repo.Migrations.AddRemainingQuoteFields do
  use Ecto.Migration

  def change do
    alter table(:quotes) do
      # Only add columns that are absolutely essential for the form
      add :quote_type, :string
      add :consignor_name, :string
      add :consignee_name, :string
      add :shipper_reference, :string
      add :value_declared, :decimal
      add :collection_instructions, :text
      add :delivery_instructions, :text
    end
  end
end
