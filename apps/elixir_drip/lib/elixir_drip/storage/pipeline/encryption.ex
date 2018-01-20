defmodule ElixirDrip.Storage.Pipeline.Encryption do
  @moduledoc false
  @dummy_state []

  use     GenStage
  require Logger
  alias   ElixirDrip.Storage.Pipeline.Common
  alias   ElixirDrip.Storage.Supervisors.CacheSupervisor, as: Cache

  @encrypted_tag "#encrypted"

  def start_link([type, subscription_options]) do
    GenStage.start_link(__MODULE__,
                        subscription_options,
                        name: Common.stage_name(__MODULE__, type))
  end

  def init(subscription_options) do
    Logger.debug("#{inspect(self())}: Pipeline Encryption started. Options: #{inspect(subscription_options)}")

    {:producer_consumer, @dummy_state, subscription_options}
  end

  def handle_events(tasks, _from, _state) do
    encrypted = Enum.map(tasks, &encryption_step(&1))

    {:noreply, encrypted, @dummy_state}
  end

  defp encryption_step(%{media: %{id: id}, content: content, type: :upload} = task) do
    Process.sleep(1000)

    Cache.put(id, content)

    Logger.debug("#{inspect(self())}: Encrypting media #{id}, size: #{byte_size(content)} bytes.")

    # TODO: Encrypt content with encryption key
    content = content <> @encrypted_tag

    %{task | content: content}
  end

  defp encryption_step(%{media: media, content: _content, status: :original, type: :download} = task) do
    Logger.debug("#{inspect(self())}: Media #{media.id} already decrypted, skipping decryption...")

    task
  end

  defp encryption_step(%{media: media, content: content, type: :download} = task) do
    Process.sleep(1000)

    Logger.debug("#{inspect(self())}: Decrypting media #{media.id}, size: #{byte_size(content)} bytes.")

    # TODO: Decrypt content with encryption key
    content = Regex.replace(~r/#{@encrypted_tag}$/, content, "")

    %{task | content: content}
  end
end

