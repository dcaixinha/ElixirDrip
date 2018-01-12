defmodule ElixirDrip.Storage.Media do
  use Ecto.Schema

  @primary_key {:id, ElixirDrip.Ecto.Ksuid, autogenerate: true}
  schema "storage_media" do
    field :filename, :string
    field :full_path, :string
    field :metadata, :map, default: %{}
    field :encryption_key, :string
    field :storage_key, :string
    field :uploaded_at, :utc_datetime

    timestamps()
  end
end
