defmodule ElixirDrip.Storage.Supervisors.Download.Pipeline do
  @moduledoc """
  A pipeline supervisor that will spawn and supervise all the GenStage processes that compose the download pipeline.
  """

  use   Supervisor
  alias ElixirDrip.Storage.Pipeline.{
    Common,
    Starter,
    Encryption,
    RemoteStorage,
    Notifier
  }

  @direction :download

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    remote_storage_subscription = [subscribe_to: [{Common.stage_name(Starter, @direction), min_demand: 1, max_demand: 10}]]
    encryption_subscription     = [subscribe_to: [{Common.stage_name(RemoteStorage, @direction), min_demand: 1, max_demand: 10}]]
    notifier_subscription       = [subscribe_to: [{Common.stage_name(Encryption, @direction), min_demand: 1, max_demand: 10}]]

    Supervisor.init([
      worker(Starter, [@direction], restart: :permanent),

      worker(RemoteStorage, [[@direction, remote_storage_subscription]],
             restart: :permanent,
             name: Common.stage_name(RemoteStorage, @direction)),

      worker(Encryption, [[@direction, encryption_subscription]],
             restart: :permanent,
             name: Common.stage_name(Encryption, @direction)),

      worker(Notifier, [[@direction, notifier_subscription]],
             restart: :permanent,
             name: Common.stage_name(Notifier, @direction))
    ],
    strategy: :rest_for_one,
    name: __MODULE__
    )
  end
end
