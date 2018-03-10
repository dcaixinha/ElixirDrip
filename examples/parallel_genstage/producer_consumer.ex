defmodule ParallelGenStage.ProducerConsumer do
  use GenStage
  alias ParallelGenStage.Producer

  def start_link(suffix) do
    GenStage.start_link(__MODULE__, suffix, name: Module.concat(__MODULE__, suffix))
  end

  def init(suffix) do
    {:producer_consumer, suffix, subscribe_to: [{Producer, min_demand: 1, max_demand: 3}]}
  end

  def handle_events(events, _from, suffix) do
    processed_events =
      events
      |> Enum.map(fn e -> "#{e}_#{suffix}" end)

    {:noreply, processed_events, suffix}
  end
end
