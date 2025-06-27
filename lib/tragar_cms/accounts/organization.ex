defmodule TragarCms.Accounts.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "organizations" do
    field :name, :string
    field :code, :string
    field :address_line_1, :string
    field :address_line_2, :string
    field :city, :string
    field :postal_code, :string
    field :country, :string, default: "South Africa"
    field :phone, :string
    field :email, :string
    field :contact_person, :string
    field :status, :string, default: "active"
    field :api_credentials, :map

    has_many :branches, TragarCms.Accounts.Branch
    has_many :users, TragarCms.Accounts.User
    has_many :quotes, TragarCms.Quotes.Quote

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [
      :name,
      :code,
      :address_line_1,
      :address_line_2,
      :city,
      :postal_code,
      :country,
      :phone,
      :email,
      :contact_person,
      :status,
      :api_credentials
    ])
    |> validate_required([:name, :code])
    |> validate_inclusion(:status, ["active", "inactive"])
    |> unique_constraint(:code)
  end
end
