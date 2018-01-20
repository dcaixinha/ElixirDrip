defmodule ElixirDrip.Storage.Supervisors.Upload.Pipeline do
  @moduledoc """
  A pipeline supervisor that will spawn and supervise all the GenStage processes that compose the upload pipeline.

  Steps:
  Upload enqueued
  |> Encryption
  |> RemoteStorage
  |> Notifier
  """

  use   Supervisor
  alias ElixirDrip.Storage.Pipeline.{
    Common,
    Starter,
    Encryption,
    RemoteStorage,
    Notifier
  }

  def start_link(type) do
    Supervisor.start_link(__MODULE__, type, name: __MODULE__)
  end

  def init(type) do

    encryption_subscription     = [subscribe_to: [{Common.stage_name(Starter, type), min_demand: 1, max_demand: 10}]]
    remote_storage_subscription = [subscribe_to: [{Common.stage_name(Encryption, type), min_demand: 1, max_demand: 10}]]
    notifier_subscription       = [subscribe_to: [{Common.stage_name(RemoteStorage, type), min_demand: 1, max_demand: 10}]]

    Supervisor.init([
      worker(Starter, [type], restart: :permanent),
      worker(Encryption, [[type, encryption_subscription]],
             restart: :permanent, name: Common.stage_name(Encryption, type)),
      worker(RemoteStorage, [[type, remote_storage_subscription]],
             restart: :permanent),
      worker(Notifier, [[type, notifier_subscription]],
             restart: :permanent, name: Common.stage_name(Notifier, type))
    ],
    strategy: :rest_for_one,
    name: __MODULE__
    )
  end
end
