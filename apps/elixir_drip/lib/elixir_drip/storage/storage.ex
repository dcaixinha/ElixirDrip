defmodule ElixirDrip.Storage do
  @moduledoc false

  alias Ecto.Changeset
  alias ElixirDrip.Repo
  alias ElixirDrip.Utils
  alias ElixirDrip.Storage.Media
  alias ElixirDrip.Storage.Provider

  @doc """
    TODO: This will trigger an Upload request
    that will be handled by the Upload Pipeline
    for now, it sequentially creates the Media on the DB
    and uploads it to the provider
  """
  def store(filename, full_path, content) do
    with %Changeset{} = changeset         <- create_initial_changeset(filename, full_path),
         %Media{storage_key: key} = media <- Repo.insert!(changeset),
         {:ok, :uploaded}                 <- Provider.upload(key, content)
    do
      stored_media = media
      |> changeset(%{uploaded_at: DateTime.utc_now()})
      |> Repo.update!()

      {:ok, stored_media}
    end
  end

  @doc """
    TODO: This will trigger a Download request
    that will be handled by the Download Pipeline
  """
  def retrieve(%Media{storage_key: storage_key}) do
    Provider.download(storage_key)
  end

  def get_media(id), do: Repo.get!(Media, id)

  defp create_initial_changeset(filename, full_path) do
    id = Ksuid.generate()

    changeset(%Media{}, %{
      id: id,
      storage_key: generate_storage_key(id, filename),
      filename: filename,
      full_path: full_path
    })
  end

  defp generate_storage_key(id, filename), do: id <> "_" <> Utils.generate_timestamp() <> Path.extname(filename)

  defp changeset(%Media{} = media, attrs) do
    media
    |> Changeset.cast(attrs, cast_attrs())
    |> Changeset.validate_required(required_attrs())
  end

  defp cast_attrs do
    [
      :filename, :full_path, :metadata,
      :encryption_key, :storage_key, :uploaded_at
    ]
  end

  defp required_attrs, do: [:filename, :full_path, :storage_key]
end
