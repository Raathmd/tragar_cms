defmodule TragarCms.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :role, :string, default: "user"
    field :status, :string, default: "active"
    field :last_login_at, :utc_datetime
    field :password_hash, :string

    belongs_to :organization, TragarCms.Accounts.Organization
    belongs_to :branch, TragarCms.Accounts.Branch
    has_many :quotes, TragarCms.Quotes.Quote, foreign_key: :created_by_user_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :username,
      :first_name,
      :last_name,
      :phone,
      :role,
      :status,
      :last_login_at,
      :password_hash,
      :organization_id,
      :branch_id
    ])
    |> validate_required([:email, :first_name, :last_name, :organization_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> validate_inclusion(:role, ["admin", "manager", "user"])
    |> validate_inclusion(:status, ["active", "inactive"])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_length(:password, min: 12, max: 72)
    |> put_password_hash()
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, Argon2.add_hash(password))
  end

  defp put_password_hash(changeset), do: changeset
end
