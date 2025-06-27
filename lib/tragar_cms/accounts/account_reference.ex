defmodule TragarCms.Accounts.AccountReference do
  use Ecto.Schema
  import Ecto.Query, warn: false
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "account_references" do
    field :reference_code, :string
    field :reference_name, :string
    field :description, :string
    field :api_username, :string
    field :api_password, :string
    field :api_station, :string
    field :status, :string, default: "active"
    field :is_default, :boolean, default: false

    belongs_to :organization, TragarCms.Accounts.Organization
    has_many :users, TragarCms.Accounts.User, foreign_key: :default_account_reference_id
    has_many :quotes, TragarCms.Quotes.Quote

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account_reference, attrs) do
    account_reference
    |> cast(attrs, [
      :reference_code,
      :reference_name,
      :description,
      :api_username,
      :api_password,
      :api_station,
      :status,
      :is_default,
      :organization_id
    ])
    |> validate_required([:reference_code, :reference_name, :organization_id])
    |> validate_inclusion(:status, ["active", "inactive"])
    |> unique_constraint([:organization_id, :reference_code])
    |> validate_length(:reference_code, max: 15)
    |> validate_length(:reference_name, max: 70)
  end

  @doc """
  Returns active account references for an organization.
  """
end
