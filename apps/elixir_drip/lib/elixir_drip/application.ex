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
    Supervisors.PipelineSupervisor,
    Workers.QueueWorker
  }

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link(
      [
        supervisor(ElixirDrip.Repo, []),
        supervisor(CacheSupervisor, [], name: CacheSupervisor),
        worker(QueueWorker, [:download], id: :download_queue, restart: :permanent),
        worker(QueueWorker, [:upload], id: :upload_queue, restart: :permanent),
        supervisor(PipelineSupervisor, [:download]),
      ],
      strategy: :one_for_one,
      name: ElixirDrip.Supervisor
    )
  end
end
