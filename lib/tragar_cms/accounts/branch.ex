defmodule TragarCms.Accounts.Branch do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "branches" do
    field :name, :string
    field :code, :string
    field :address_line_1, :string
    field :address_line_2, :string
    field :city, :string
    field :postal_code, :string
    field :phone, :string
    field :email, :string
    field :contact_person, :string
    field :status, :string, default: "active"

    belongs_to :organization, TragarCms.Accounts.Organization
    has_many :users, TragarCms.Accounts.User
    has_many :quotes, TragarCms.Quotes.Quote

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(branch, attrs) do
    branch
    |> cast(attrs, [
      :name,
      :code,
      :address_line_1,
      :address_line_2,
      :city,
      :postal_code,
      :phone,
      :email,
      :contact_person,
      :status,
      :organization_id
    ])
    |> validate_required([:name, :code, :organization_id])
    |> validate_inclusion(:status, ["active", "inactive"])
    |> unique_constraint([:organization_id, :code])
  end
end
