defmodule ParallelGenStage.TestB do
  alias ElixirDrip.Pipeliner

  alias ParallelGenStage.ProdB
  alias ParallelGenStage.ProdConsB
  alias ParallelGenStage.ConsB

  use Pipeliner,
    name: :guinea_pipeline, min_demand: 4, max_demand: 8

  start ProdB,
    args: [275, "hi there"], count: 2
  step ProdConsB,
    args: ["W", "not needed"], count: 3, min_demand: 1, max_demand: 10
  step ProdConsB,
    args: ["Z", "ups, just lookin' around"], count: 3, min_demand: 1, max_demand: 3
  finish ConsB,
    args: ["JOZe", "Rico"], count: 2
end


defmodule ParallelGenStage.ProdB do
  use ElixirDrip.Pipeliner.Producer, args: [:initial, :dont_care]

  @impl true
  def handle_demand(demand, [counter, dont_care]) do
    events = Enum.to_list(counter..(counter + demand - 1))

    {:noreply, events, [counter + demand, dont_care]}
  end
end

defmodule ParallelGenStage.ProdConsB do
  use ElixirDrip.Pipeliner.Consumer, args: [:suffix, :not_needed], type: :producer_consumer

  @impl true
  def handle_events(events, _from, [suffix, not_needed]) do
    processed_events =
      events
      |> Enum.map(fn e -> "#{e}_#{suffix}" end)

    {:noreply, processed_events, [suffix, not_needed]}
  end
end

defmodule ParallelGenStage.ConsB do
  use ElixirDrip.Pipeliner.Consumer, args: [:foo, :bar], type: :consumer

  @impl true
  def handle_events(events, _from, [foo, bar]) do
    for event <- events do
      Process.sleep(1000)

      IO.inspect({self(), foo, bar, event})
    end

    # As a consumer we never emit events
    {:noreply, [], [foo, bar]}
  end
end
