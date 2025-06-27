defmodule TragarCms.Repo.Migrations.AddRemainingQuoteFields do
  use Ecto.Migration

  def change do
    alter table(:quotes) do
      # Only add quote_type which is essential for the form
      add :quote_type, :string
    end
  end
end
