defmodule ParallelGenStage.StreamlinedProducer do
  use ElixirDrip.Pipeliner.Producer, args: [:initial]

  @impl true
  def handle_demand(demand, counter) do
    events = Enum.to_list(counter..(counter + demand - 1))
    {:noreply, events, counter + demand}
  end
end
