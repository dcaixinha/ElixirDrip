defmodule ElixirDrip.Storage.Pipeline.Encryption do
  @moduledoc false
  @dummy_state :ok

  use     GenStage
  require Logger

  def start_link(subscription_options) do
    GenStage.start_link(__MODULE__, subscription_options, name: __MODULE__)
  end

  def init(subscription_options) do
    Logger.debug("#{inspect(self())}: Pipeline Encryption started. Options: #{inspect(subscription_options)}")

    {:producer_consumer, @dummy_state, subscription_options}
  end

  def handle_events(tasks, _from, _state) do
    encrypted = Enum.map(tasks, &encryption_step(&1))

    {:noreply, encrypted, @dummy_state}
  end

  defp encryption_step(%{media: media, content: content, type: :upload} = task) do
    Logger.debug("#{inspect(self())}: Encrypting media #{media.id}, size: #{byte_size(content)} bytes.")
    Process.sleep(1000)
    # TODO: Encrypt content with encryption key
    content = content <> "#encrypted"

    %{task | content: content}
  end

  defp encryption_step(%{media: media, content: _content, status: :original, type: :download} = task) do
    Logger.debug("#{inspect(self())}: Media #{media.id} already decrypted, skipping decryption...")

    task
  end

  defp encryption_step(%{media: media, content: content, type: :download} = task) do
    Logger.debug("#{inspect(self())}: Decrypting media #{media.id}, size: #{byte_size(content)} bytes.")
    Process.sleep(1000)
    # TODO: Decrypt content with encryption key
    content = content <> "#decrypted"

    %{task | content: content}
  end
end

