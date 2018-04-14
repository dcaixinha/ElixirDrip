defmodule ElixirDrip.Repo.Migrations.AddFkFromMediaToUsers do
  use Ecto.Migration

  def change do
    alter table(:storage_media) do
      add :user_id, references(:users, type: :string)
    end
  end
end
