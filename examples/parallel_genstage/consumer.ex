defmodule ParallelGenStage.Consumer do
  use GenStage
  alias ParallelGenStage.ProducerConsumer

  def start_link(name, suffixes) do
    GenStage.start_link(__MODULE__, {name, suffixes}, name: Module.concat(__MODULE__, name))
  end

  def init({name, suffixes}) do
    subscriptions = suffixes
                    |> Enum.map(fn suffix -> {
                      Module.concat(ProducerConsumer, suffix),
                      min_demand: 1, max_demand: 5
                    } end)

    {:consumer, name, subscribe_to: subscriptions}
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
