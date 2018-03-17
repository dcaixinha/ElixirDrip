defmodule ParallelGenStage.GuineaProducer do
  use ParallelGenStage.Pipeliner.Producer, args: [:initial]

  def handle_demand(demand, counter) do
    events = Enum.to_list(counter..(counter + demand - 1))
    {:noreply, events, counter + demand}
  end
end
