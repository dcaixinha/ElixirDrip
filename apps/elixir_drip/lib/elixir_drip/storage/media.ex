defmodule ElixirDrip.Storage.Media do
  use Ecto.Schema

  alias __MODULE__
  alias Ecto.Changeset
  alias ElixirDrip.Utils
  alias ElixirDrip.Storage.Providers.Encryption.Simple, as: Encryption
  alias ElixirDrip.Storage.{
    Owner,
    MediaOwners
  }

  @primary_key {:id, ElixirDrip.Ecto.Ksuid, autogenerate: true}
  schema "storage_media" do
    field :user_id, ElixirDrip.Ecto.Ksuid
    field :file_name, :string
    field :full_path, :string
    field :file_size, :integer
    field :metadata, :map, default: %{}
    field :encryption_key, :string
    field :storage_key, :string
    field :uploaded_at, :utc_datetime
    many_to_many :owners, Owner, join_through: MediaOwners, join_keys: [media_id: :id, user_id: :id]

    timestamps()
  end

  def create_initial_changeset(user_id, file_name, full_path) do
    id = Ksuid.generate()

    create_changeset(%Media{}, %{
      id: id,
      user_id: user_id,
      storage_key: generate_storage_key(id, file_name),
      encryption_key: Encryption.generate_key(),
      file_name: file_name,
      full_path: full_path
    })
  end

  def create_changeset(%Media{} = media, attrs) do
    media
    |> Changeset.cast(attrs, cast_attrs())
    |> Changeset.validate_required(required_attrs())
  end

  defp generate_storage_key(id, file_name), do: id <> "_" <> Utils.generate_timestamp() <> Path.extname(file_name)

  defp cast_attrs do
    [
      :id, :user_id, :file_name, :full_path, :metadata,
      :encryption_key, :storage_key, :uploaded_at
    ]
  end

  defp required_attrs, do: [:id, :user_id, :file_name, :full_path, :storage_key]
end
