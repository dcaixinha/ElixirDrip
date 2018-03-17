defmodule ParallelGenStage.GuineaConsumer do
  use GenStage

  def start_link(name, sub_options) do
    GenStage.start_link(__MODULE__, {name, sub_options}, name: name)
  end

  def init({name, sub_options}) do
    {:consumer, name, subscribe_to: sub_options}
  end

  def handle_events(events, _from, name) do
    for event <- events do
      Process.sleep(1000)

      IO.inspect({self(), name, event})
    end

    # As a consumer we never emit events
    {:noreply, [], name}
  end
end
