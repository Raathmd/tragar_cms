defmodule TragarCms.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias TragarCms.Repo

  alias TragarCms.Accounts.{Organization, Branch, User, AccountReference}

  @doc """
  Returns the list of organizations.
  """
  def list_organizations do
    Repo.all(Organization)
  end

  @doc """
  Gets a single organization.
  """
  def get_organization!(id), do: Repo.get!(Organization, id)

  @doc """
  Creates a organization.
  """
  def create_organization(attrs \\ %{}) do
    %Organization{}
    |> Organization.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the list of account references for an organization.
  """
  def list_account_references_for_organization(organization_id) do
    AccountReference.for_organization(organization_id)
    |> Repo.all()
  end

  @doc """
  Gets a single account reference.
  """
  def get_account_reference!(id), do: Repo.get!(AccountReference, id)

  @doc """
  Creates an account reference.
  """
  def create_account_reference(attrs \\ %{}) do
    %AccountReference{}
    |> AccountReference.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an account reference.
  """
  def update_account_reference(%AccountReference{} = account_reference, attrs) do
    account_reference
    |> AccountReference.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets the default account reference for an organization.
  """
  def get_default_account_reference(organization_id) do
    from(ar in AccountReference,
      where:
        ar.organization_id == ^organization_id and ar.is_default == true and ar.status == "active",
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Gets a user with preloaded account reference.
  """
  def get_user_with_account_reference!(id) do
    Repo.get!(User, id)
    |> Repo.preload([:default_account_reference, :organization])
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end
end
