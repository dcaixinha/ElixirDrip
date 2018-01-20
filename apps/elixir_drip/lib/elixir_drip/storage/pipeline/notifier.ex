defmodule ElixirDrip.Storage.Pipeline.Notifier do
  @moduledoc false

  use     GenStage
  require Logger
  alias   ElixirDrip.Storage.Pipeline.Common
  alias   ElixirDrip.Storage.Supervisors.CacheSupervisor, as: Cache

  @dummy_state :ok

  def start_link([type, subscription_options]) do
    GenStage.start_link(__MODULE__,
                        subscription_options,
                        name: Common.stage_name(__MODULE__, type))
  end

  def init(subscription_options) do
    Logger.debug("#{inspect(self())}: Pipeline Notifier started. Options: #{inspect(subscription_options)}")

    {:consumer, @dummy_state, subscription_options}
  end

  def handle_events(tasks, _from, _state) do
    Enum.each(tasks, &notify_step(&1))

    {:noreply, [], @dummy_state}
  end

  defp notify_step(%{media: media, content: content, type: :upload}) do
    # TODO: Invoke the notifier instead!
    Logger.debug("#{inspect(self())}: NOTIFICATION! Uploaded media #{media.id} to #{media.storage_key} with size: #{byte_size(content)} bytes.")
  end

  defp notify_step(%{media: %{id: id}, content: content, type: :download}) do
    # TODO: Invoke the notifier instead!
    Cache.put_or_refresh(id, content)

    Logger.debug("#{inspect(self())}: NOTIFICATION! Downloaded media #{id}, content: #{inspect(content)}, size: #{byte_size(content)} bytes.")
  end
end

