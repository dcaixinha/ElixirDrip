defmodule ParallelGenStage.StreamlinedProducerConsumer do
  use ElixirDrip.Pipeliner.Consumer, args: [:suffix], type: :producer_consumer

  @impl true
  def handle_events(events, _from, suffix) do
    processed_events =
      events
      |> Enum.map(fn e -> "#{e}_#{suffix}" end)

    {:noreply, processed_events, suffix}
  end
end
