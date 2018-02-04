defmodule ElixirDrip.Storage do
  @moduledoc false

  import Ecto.Query
  alias Ecto.Changeset
  alias ElixirDrip.Repo
  alias ElixirDrip.Utils
  alias ElixirDrip.Storage.Workers.QueueWorker, as: Queue
  alias ElixirDrip.Storage.Media
  alias ElixirDrip.Storage.Providers.Encryption.Simple, as: Encryption

  @doc """
    It sequentially creates the Media on the DB and
    triggers an Upload request handled by the Upload Pipeline.
  """
  def store(file_name, full_path, content) do
    with %Changeset{} = changeset          <- create_initial_changeset(file_name, full_path),
         %Media{storage_key: _key} = media <- Repo.insert!(changeset)
    do
      upload_task = %{
        media: media,
        content: content,
        type: :upload
      }

      Queue.enqueue(Queue.Upload, upload_task)

      {:ok, :upload_enqueued}
    end
  end

  def set_upload_timestamp(%Media{} = media) do
    media
    |> changeset(%{uploaded_at: DateTime.utc_now()})
    |> Repo.update!()
  end

  @doc """
    It triggers a Download request
    that will be handled by the Download Pipeline
  """
  def retrieve(%Media{} = media) do
    download_task = %{
      media: media,
      type: :download
    }
    Queue.enqueue(Queue.Download, download_task)

    {:ok, :download_enqueued}
  end

  def get_media(id), do: Repo.get!(Media, id)

  def list_all_media do
    Media
    |> Repo.all()
  end

  def get_last_media do
    Repo.one(
      from media in Media,
      order_by: [desc: media.id],
      limit: 1
    )
  end

  defp create_initial_changeset(file_name, full_path) do
    id = Ksuid.generate()

    changeset(%Media{}, %{
      id: id,
      storage_key: generate_storage_key(id, file_name),
      encryption_key: Encryption.generate_key(),
      file_name: file_name,
      full_path: full_path
    })
  end

  defp generate_storage_key(id, file_name), do: id <> "_" <> Utils.generate_timestamp() <> Path.extname(file_name)

  defp changeset(%Media{} = media, attrs) do
    media
    |> Changeset.cast(attrs, cast_attrs())
    |> Changeset.validate_required(required_attrs())
  end

  defp cast_attrs do
    [
      :id, :file_name, :full_path, :metadata,
      :encryption_key, :storage_key, :uploaded_at
    ]
  end

  defp required_attrs, do: [:id, :file_name, :full_path, :storage_key]
end
