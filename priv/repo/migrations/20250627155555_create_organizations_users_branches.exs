defmodule TragarCms.Repo.Migrations.CreateOrganizationsUsersBranches do
  use Ecto.Migration

  def change do
    # Organizations table
    create table(:organizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :code, :string, null: false
      add :address_line_1, :string
      add :address_line_2, :string
      add :city, :string
      add :postal_code, :string
      add :country, :string, default: "South Africa"
      add :phone, :string
      add :email, :string
      add :contact_person, :string
      add :status, :string, default: "active", null: false
      add :api_credentials, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:code])
    create index(:organizations, [:name])
    create index(:organizations, [:status])

    # Branches table
    create table(:branches, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :string, null: false
      add :code, :string, null: false
      add :address_line_1, :string
      add :address_line_2, :string
      add :city, :string
      add :postal_code, :string
      add :phone, :string
      add :email, :string
      add :contact_person, :string
      add :status, :string, default: "active", null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:branches, [:organization_id, :code])
    create index(:branches, [:organization_id])
    create index(:branches, [:name])
    create index(:branches, [:status])

    # Users table
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :branch_id, references(:branches, type: :binary_id, on_delete: :nilify_all)
      add :email, :string, null: false
      add :username, :string
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :phone, :string
      add :role, :string, default: "user", null: false
      add :status, :string, default: "active", null: false
      add :last_login_at, :utc_datetime
      add :password_hash, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create index(:users, [:organization_id])
    create index(:users, [:branch_id])
    create index(:users, [:role])
    create index(:users, [:status])

    # Add organization_id to quotes table
    alter table(:quotes) do
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all)
      add :branch_id, references(:branches, type: :binary_id, on_delete: :nilify_all)
      add :created_by_user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:quotes, [:organization_id])
    create index(:quotes, [:branch_id])
    create index(:quotes, [:created_by_user_id])
  end
end
