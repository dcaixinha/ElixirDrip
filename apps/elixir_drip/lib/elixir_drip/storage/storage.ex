defmodule ElixirDrip.Storage do
  @moduledoc false

  import Ecto.Query
  alias Ecto.Changeset
  alias ElixirDrip.Repo
  alias ElixirDrip.Storage.Workers.QueueWorker, as: Queue
  alias ElixirDrip.Storage.Media
  alias ElixirDrip.Storage.Owner

  @doc """
    It sequentially creates the Media on the DB and
    triggers an Upload request handled by the Upload Pipeline.
  """
  def store(user_id, file_name, full_path, content) do
    with %Owner{} = owner <- get_owner(user_id),
         %Changeset{} = changeset <- Media.create_initial_changeset(owner.id, file_name, full_path),
         %Changeset{} = changeset <- Changeset.put_assoc(changeset, :owners, [owner]),
         %Media{storage_key: _key} = media <- Repo.insert!(changeset)
    do
      upload_task = %{
        media: media,
        content: content,
        type: :upload
      }

      Queue.enqueue(Queue.Upload, upload_task)

      {:ok, :upload_enqueued, media}
    end
  end

  def set_upload_timestamp(%Media{} = media) do
    media
    |> Media.create_changeset(%{uploaded_at: DateTime.utc_now()})
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

    {:ok, :download_enqueued, media}
  end

  def get_media(id), do: Repo.get!(Media, id)

  def get_owner(id, preloaded \\ false)
  def get_owner(id, false),
    do: Repo.get!(Owner, id)
  def get_owner(id, true),
    do: Repo.get!(Owner, id) |> Repo.preload(:files)

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
end
