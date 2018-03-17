defmodule ParallelGenStage.GuineaProducerConsumer do
  use ParallelGenStage.Pipeliner.Consumer, args: [:suffix], type: :producer_consumer

  def handle_events(events, _from, suffix) do
    processed_events =
      events
      |> Enum.map(fn e -> "#{e}_#{suffix}" end)

    {:noreply, processed_events, suffix}
  end
end
