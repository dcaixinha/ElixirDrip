defmodule ElixirDrip.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :string, primary_key: true, size: 27
      add :username, :string
      add :hashed_password, :string

      timestamps(type: :utc_datetime)
    end
  end
end
