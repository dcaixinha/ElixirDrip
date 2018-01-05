defmodule ElixirDrip.Storage.Media do
  use Ecto.Schema

  @primary_key {:id, ElixirDrip.Ecto.Ksuid, autogenerate: true}
  schema "storage_media" do
    field :path, :string
    field :encryption_key, :string
    field :metadata, :map

    timestamps()
  end
end
