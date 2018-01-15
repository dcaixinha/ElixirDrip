defmodule ElixirDrip.Storage.Pipeline.RemoteStorage do
  @moduledoc false

  use     GenStage
  require Logger
  alias   ElixirDrip.Storage
  alias   ElixirDrip.Storage.Provider

  @dummy_state :ok

  def start_link() do
    GenStage.start_link(__MODULE__, @dummy_state, name: __MODULE__)
  end

  def init(_) do
    {:producer_consumer, @dummy_state}
  end

  def handle_events(tasks, _from, _state) do
    processed = Enum.map(tasks, &remote_storage_step(&1))

    {:noreply, processed, @dummy_state}
  end

  defp remote_storage_step(%{media: media, content: content, type: :upload} = task) do
    Logger.debug("#{inspect(self())}: Uploading media #{media.id} to #{media.storage_key}, size: #{byte_size(content)} bytes.")
    Process.sleep(2000)

    {:ok, :uploaded} = Provider.upload(media.storage_key, content)

    %{task | media: Storage.set_upload_timestamp(media)}
  end

  defp remote_storage_step(%{media: media, type: :download} = task) do
    Process.sleep(2000)
    # TODO: Check if there is a CacheWorker for this media.id
    # If there is:
    #   - Fetch the content from there and
    #   put status: :original, content: fetched_content
    #   on the returned task
    # If not:
    #   - Proceed normally, without any status

    {:ok, content} = Provider.download(media.storage_key)
    Logger.debug("#{inspect(self())}: Just downloaded media #{media.id}, content: #{inspect(content)}, size: #{byte_size(content)} bytes.")

    Map.put(task, :content, content)
  end
end

