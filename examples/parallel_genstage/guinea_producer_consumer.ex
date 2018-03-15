defmodule ParallelGenStage.GuineaProducerConsumer do
  use GenStage

  def start_link(suffix, sub_options) do
    GenStage.start_link(__MODULE__, {suffix, sub_options}, name: Module.concat(__MODULE__, suffix))
  end

  def init({suffix, sub_options}) do
    {:producer_consumer, suffix, subscribe_to: sub_options}
  end

  def handle_events(events, _from, suffix) do
    processed_events =
      events
      |> Enum.map(fn e -> "#{e}_#{suffix}" end)

    {:noreply, processed_events, suffix}
  end
end
