defmodule TragarCms.Repo.Migrations.CreateQuotes do
  use Ecto.Migration

  def change do
    create table(:quotes) do
      add :content, :text, null: false
      add :author, :string, null: false
      add :source, :string
      add :category, :string
      add :status, :string, default: "pending", null: false

      timestamps()
    end

    create index(:quotes, [:author])
    create index(:quotes, [:category])
    create index(:quotes, [:status])
  end
end
