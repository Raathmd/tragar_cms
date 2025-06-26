defmodule TragarCms.Repo.Migrations.AddItemsToQuotes do
  use Ecto.Migration

  def change do
    alter table(:quotes) do
      # Store JSON as text for SQLite compatibility
      add :items, :text
    end
  end
end
