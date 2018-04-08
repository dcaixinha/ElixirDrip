defmodule ElixirDrip.Repo.Migrations.AddFileSizeToMedia do
  use Ecto.Migration

  def change do
    alter table(:storage_media) do
      add :file_size, :integer
    end
  end
end
