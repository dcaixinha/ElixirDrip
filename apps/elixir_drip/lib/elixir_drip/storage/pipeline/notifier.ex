defmodule ElixirDrip.Storage.Pipeline.Notifier do
  @moduledoc false

  use     GenStage
  require Logger

  @dummy_state :ok

  def start_link() do
    GenStage.start_link(__MODULE__, @dummy_state, name: __MODULE__)
  end

  def init(_) do
    {:consumer, @dummy_state}
  end

  def handle_events(tasks, _from, _state) do
    Enum.each(tasks, &notify_step(&1))

    {:noreply, [], @dummy_state}
  end

  defp notify_step(%{media: media, content: content, type: :upload}) do
    # TODO: Invoke the notifier instead!
    Logger.debug("#{inspect(self())}: NOTIFICATION! Uploaded media #{media.id} to #{media.storage_key} with size: #{byte_size(content)} bytes.")
  end

  defp notify_step(%{media: media, content: content, type: :download}) do
    Logger.debug("#{inspect(self())}: NOTIFICATION! Downloaded media #{media.id}, content: #{inspect(content)}, size: #{byte_size(content)} bytes.")
  end
end

