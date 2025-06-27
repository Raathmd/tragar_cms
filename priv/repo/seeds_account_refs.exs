# Seeds for account references

# Get the demo organization
org = TragarCms.Repo.get_by!(TragarCms.Accounts.Organization, code: "demo-org-123")

# Remove existing account references
import Ecto.Query
from(ar in TragarCms.Accounts.AccountReference) |> TragarCms.Repo.delete_all()

# Create account references without API credentials
ar1 = %TragarCms.Accounts.AccountReference{
  reference_code: "DEMO001",
  reference_name: "Demo Account 1",
  description: "Primary demo account for testing",
  status: "active",
  is_default: true,
  organization_id: org.id
}

ar2 = %TragarCms.Accounts.AccountReference{
  reference_code: "DEMO002",
  reference_name: "Demo Account 2",
  description: "Secondary demo account for testing",
  status: "active",
  is_default: false,
  organization_id: org.id
}

TragarCms.Repo.insert!(ar1)
TragarCms.Repo.insert!(ar2)

IO.puts("Created account references successfully!")
