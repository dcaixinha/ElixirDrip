defmodule ParallelGenStage.StreamlinedConsumer do
  use ElixirDrip.Pipeliner.Consumer, args: [:foo, :bar], type: :consumer

  def handle_events(events, _from, [foo, bar]) do
    for event <- events do
      Process.sleep(1000)

      IO.inspect({self(), foo, bar, event})
    end

    # As a consumer we never emit events
    {:noreply, [], [foo, bar]}
  end
end
