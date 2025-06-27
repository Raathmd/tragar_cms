defmodule TragarCms.Repo.Migrations.CreateAccountReferences do
  use Ecto.Migration

  def change do
    create table(:account_references, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :reference_code, :string, null: false
      add :reference_name, :string, null: false
      add :description, :string
      add :status, :string, default: "active", null: false
      add :is_default, :boolean, default: false

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:account_references, [:organization_id, :reference_code])
    create index(:account_references, [:organization_id])
    create index(:account_references, [:reference_code])
    create index(:account_references, [:status])
    create index(:account_references, [:is_default])

    # Add default_account_reference_id to users table
    alter table(:users) do
      add :default_account_reference_id,
          references(:account_references, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:users, [:default_account_reference_id])

    # Add account_reference_id to quotes table for tracking which account was used
    alter table(:quotes) do
      add :account_reference_id,
          references(:account_references, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:quotes, [:account_reference_id])
  end
end
