defmodule TragarCms.Repo.Migrations.AddTotalAmountToQuotes do
  use Ecto.Migration

  def change do
    alter table(:quotes) do
      add :total_amount, :decimal
    end
  end
end
