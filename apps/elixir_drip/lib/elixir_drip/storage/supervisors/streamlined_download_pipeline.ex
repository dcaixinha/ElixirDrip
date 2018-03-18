defmodule ElixirDrip.Storage.Supervisors.Download.StreamlinedPipeline do
  alias ElixirDrip.Pipeliner
  alias ElixirDrip.Storage.Pipeline.{
    Starter,
    Encryption,
    RemoteStorage,
    Notifier
  }

  use Pipeliner,
    name: :download_pipeline, min_demand: 1, max_demand: 10, count: 1

  start Starter, args: [:download]
  step RemoteStorage
  step Encryption
  finish Notifier
end
