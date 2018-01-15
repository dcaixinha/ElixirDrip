defmodule ElixirDrip.Storage.Pipeline.Starter do
  @moduledoc false

  use     GenStage
  require Logger
  alias   ElixirDrip.Storage.Workers.QueueWorker

  @no_of_tasks 5

  def start_link(type) do
    GenStage.start_link(__MODULE__, type, name: __MODULE__)
  end

  def init(type) do
    {
      :producer,
      %{queue: QueueWorker.queue_name(type), type: type}
    }
  end

  def handle_demand(demand, %{queue: queue, type: type} = state) when demand > 0 do
    Logger.debug("#{inspect(self())}: Starter, handling #{demand} demand for #{type}")

    demand = case demand <= @no_of_tasks do
      true  -> demand
      _     -> @no_of_tasks
    end


    tasks = queue
            |> QueueWorker.dequeue(demand)
            |> Enum.map(&Map.put(&1, :type, type))

    {:noreply, tasks, state}
  end
end
