defmodule ElixirDrip.Application do
  @moduledoc """
  The ElixirDrip Application Service.

  The elixir_drip system business domain lives in this application.

  Exposes API to clients such as the `ElixirDripWeb` application
  for use in channels, controllers, and elsewhere.
  """
  use Application

  alias ElixirDrip.Storage.{
    Supervisors.CacheSupervisor,
    Workers.QueueWorker
  }

  alias ElixirDrip.Storage.Pipeline.{
    Starter,
    Encryption,
    RemoteStorage,
    Notifier
  }

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    remote_storage_subscription = [subscribe_to: [{Starter, min_demand: 1, max_demand: 10}]]
    encryption_subscription     = [subscribe_to: [{RemoteStorage, min_demand: 1, max_demand: 10}]]
    notifier_subscription       = [subscribe_to: [{Encryption, min_demand: 1, max_demand: 10}]]

    Supervisor.start_link(
      [
        supervisor(ElixirDrip.Repo, []),
        supervisor(CacheSupervisor, [], name: CacheSupervisor),
        worker(QueueWorker, [:download], id: :download_queue, restart: :permanent),
        worker(QueueWorker, [:upload], id: :upload_queue, restart: :permanent),
        worker(Starter, [:download], restart: :permanent),
        worker(RemoteStorage, [remote_storage_subscription], restart: :permanent),
        worker(Encryption, [encryption_subscription], restart: :permanent),
        worker(Notifier, [notifier_subscription], restart: :permanent)
      ],
      strategy: :one_for_one,
      name: ElixirDrip.Supervisor
    )
  end
end
