defmodule ElixirDrip.Storage.Supervisors.PipelineSupervisor do
  @moduledoc """
  A pipeline supervisor that will spawn and supervise all the GenStage processes that compose the pipeline.
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
    remote_storage_subscription = [subscribe_to: [{Common.stage_name(Starter, type), min_demand: 1, max_demand: 10}]]
    encryption_subscription     = [subscribe_to: [{Common.stage_name(RemoteStorage, type), min_demand: 1, max_demand: 10}]]
    notifier_subscription       = [subscribe_to: [{Common.stage_name(Encryption, type), min_demand: 1, max_demand: 10}]]

    Supervisor.init([
      worker(Starter, [type], restart: :permanent),
      worker(RemoteStorage, [[type, remote_storage_subscription]],
             restart: :permanent),
      worker(Encryption, [[type, encryption_subscription]],
             restart: :permanent, name: Common.stage_name(Encryption, type)),
      worker(Notifier, [[type, notifier_subscription]],
             restart: :permanent, name: Common.stage_name(Notifier, type))
    ],
    strategy: :rest_for_one,
    name: name_for(type)
    )
  end

  defp name_for(type) do
    type = type
           |> Atom.to_string()
           |> String.capitalize()

    Module.concat(__MODULE__, type)
  end
end
