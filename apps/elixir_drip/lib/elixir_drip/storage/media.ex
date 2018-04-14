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

  def create_initial_changeset(user_id, file_name, full_path, file_size) do
    id = Ksuid.generate()

    create_changeset(%Media{}, %{
      id: id,
      user_id: user_id,
      storage_key: generate_storage_key(id, file_name),
      encryption_key: Encryption.generate_key(),
      file_name: file_name,
      full_path: full_path,
      file_size: file_size,
    })
  end

  def create_changeset(%Media{} = media, attrs) do
    media
    |> Changeset.cast(attrs, cast_attrs())
    |> Changeset.validate_required(required_attrs())
    |> validate_field(:full_path)
    |> validate_field(:file_name)
  end

  def validate_field(changeset, :full_path) do
    validator = &is_valid_path?/1
    error_msg = "Invalid full path"

    _validate_field(changeset, :full_path, validator, error_msg)
  end

  def validate_field(changeset, :file_name) do
    validator = &is_valid_name?/1
    error_msg = "Invalid file name"

    _validate_field(changeset, :file_name, validator, error_msg)
  end

  defp _validate_field(changeset, field, validator, error_msg) do
    Changeset.validate_change(changeset, field, fn _, value ->
      case validator.(value) do
        {:ok, :valid} -> []
        _ -> [{field, error_msg}]
      end
    end)
  end

  def is_valid_path?(path) when is_binary(path) do
    valid? = String.starts_with?(path, "$") && !String.ends_with?(path, "/")

     case valid? do
        true -> {:ok, :valid}
        false -> {:error, :invalid_path}
      end
  end

  def is_valid_name?(name) when is_binary(name) do
    valid? = byte_size(name) > 0 && !String.contains?(name, "/")

     case valid? do
        true -> {:ok, :valid}
        false -> {:error, :invalid_name}
      end
  end


  defp generate_storage_key(id, file_name), do: id <> "_" <> Utils.generate_timestamp() <> Path.extname(file_name)

  defp cast_attrs,
    do: [
      :id, :user_id, :file_name, :full_path, :file_size, :metadata,
      :encryption_key, :storage_key, :uploaded_at
      ]

  defp required_attrs,
    do: [:id, :user_id, :file_name, :full_path, :file_size, :storage_key]
end
