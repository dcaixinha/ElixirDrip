defmodule ElixirDrip.Storage do
  @moduledoc false

  import ElixirDrip.Storage.Macros
  import Ecto.Query
  alias Ecto.Changeset
  alias ElixirDrip.Repo
  alias ElixirDrip.Storage.Workers.QueueWorker, as: Queue
  alias ElixirDrip.Storage.{
    Media,
    Owner,
    MediaOwners
  }

  @doc """
    It sequentially creates the Media on the DB and
    triggers an Upload request handled by the Upload Pipeline.
  """
  def store(user_id, file_name, full_path, content) do
    # TODO: Don't allow a '/' on the file_name,
    # use custom ecto validation
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
    If the media belongs to the user,
    it triggers a Download request
    that will be handled by the Download Pipeline
  """
  def retrieve(user_id, media_id) do
    user_media = user_media_query(user_id)

    media_query = from [_mo, m] in user_media,
      where: m.id == ^media_id,
      select: m

    case Repo.one(media_query) do
      nil   -> {:error, :not_found}
      media -> _retrieve(media)
    end
  end

  def get_all_media(user_id) do
    # we can only do one `select` per query,
    # that's why we don't do any `select` on the
    # user_media_query
    # The alternative would be to use subqueries
    user_media = user_media_query(user_id)
    media_query = from [_mo, m] in user_media,
      select: m

    Repo.all(media_query)
  end

  def media_by_folder(user_id, folder_path) do
    user_media_on_folder = user_media_on_folder(user_id, folder_path)
    folder_media = from e in subquery(user_media_on_folder),
      select: %{
        id: e.id,
        file_name: e.file_name,
        full_path: e.full_path,
        remaining_path: e.remaining_path,
        is_folder: is_folder(e.remaining_path)
      }

    result = folder_media
    |> Repo.all()
    |> Enum.reduce(%{files: [], folders: %{}},
                   fn(entry, result) ->
                     case entry[:is_folder] do
                       true ->
                         folder_result = update_folder_result(result, entry)
                         Map.put(result, :folders, folder_result)
                       false ->
                         files_result = update_files_result(result, entry)
                         Map.put(result, :files, files_result)
                     end
                   end)

    folder_entry = result[:folders]
    Map.put(result, :folders, Map.values(folder_entry))
  end

  defp update_files_result(%{files: files_result}, entry) do
    new_entry = Map.take(entry, [:file_name, :full_path, :id])

    [new_entry | files_result]
    |> Enum.reverse()
  end

  defp update_folder_result(%{folder: folder_result}, entry) do
    folder_name = extract_folder_name(entry)

    updated_folder_entry = case Map.has_key?(folder_result, folder_name) do
      true -> increment_folder_files(folder_result[folder_name])
      false -> %{folder_name: folder_name, files: 1}
    end

    Map.put(folder_result, folder_name, updated_folder_entry)
  end

  defp extract_folder_name(%{remaining_path: path}),
    do: Path.split(path) |> Enum.at(1)

  defp increment_folder_files(%{files: files} = folder_entry),
    do: %{folder_entry | files: files + 1}

  defp user_media_on_folder(user_id, folder_path) do
    folder_path_size = String.length(folder_path)
    folder_path_size = -folder_path_size
    user_media = user_media_query(user_id)

    # Example without macro, that works
    # select: [m.id, fragment("length(right(?, ?))", m.full_path, ^folder_path_size)]
    from [_mo, m] in user_media,
      where: like(m.full_path, ^"#{folder_path}%"),
      select: %{
        id: m.id,
        full_path: m.full_path,
        file_name: m.file_name,
        remaining_path: remaining_path(^folder_path_size, m.full_path)
      }
  end

  def share(user_id, media_id, allowed_user_id) do
    with {:ok, :owner} <- is_owner?(user_id, media_id) do
      %MediaOwners{}
      |> Changeset.cast(%{user_id: allowed_user_id, media_id: media_id}, [:user_id, :media_id])
      |> Changeset.unique_constraint(:existing_share, name: :single_share_index)
      |> Repo.insert()
    else
      error -> error
    end
  end

  def delete(user_id, media_id) do
    with {:ok, :owner} <- is_owner?(user_id, media_id) do
      # Given we have the foreign key with
      # on_delete: :delete_all option
      Repo.delete(media_id)
    else
      error -> error
    end
  end

  defp is_owner?(user_id, media_id) do
    (from m in Media,
      where: m.id == ^media_id,
      where: m.user_id == ^user_id)
      |> Repo.one()
      |> case do
        nil -> {:error, :not_owner}
        _ -> {:ok, :owner}
      end
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

  defp user_media_query(user_id) do
    from media_owner in MediaOwners,
      join: media in Media,
      on: media_owner.media_id == media.id,
      where: media_owner.user_id == ^user_id
  end

  defp _retrieve(%Media{} = media) do
    download_task = %{
      media: media,
      type: :download
    }
    Queue.enqueue(Queue.Download, download_task)

    {:ok, :download_enqueued, media}
  end
end
