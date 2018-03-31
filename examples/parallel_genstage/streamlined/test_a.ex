defmodule ParallelGenStage.TestA do
  alias ElixirDrip.Pipeliner

  alias ParallelGenStage.ProdA
  alias ParallelGenStage.ProdConsA
  alias ParallelGenStage.ConsA

  use Pipeliner,
    name: :guinea_pipeline_a, min_demand: 4, max_demand: 8

  start ProdA,
    args: [275], count: 2
  step ProdConsA,
    args: ["W"], count: 3, min_demand: 1, max_demand: 10
  step ProdConsA,
    args: ["Z"], count: 3, min_demand: 1, max_demand: 3
  finish ConsA,
    args: ["Rico"], count: 2
end


defmodule ParallelGenStage.ProdA do
  use ElixirDrip.Pipeliner.Producer, args: [:initial]

  @impl GenStage
  def handle_demand(demand, [counter]) do
    events = Enum.to_list(counter..(counter + demand - 1))
    {:noreply, events, [counter + demand]}
  end
end

defmodule ParallelGenStage.ProdConsA do
  use ElixirDrip.Pipeliner.Consumer, args: [:suffix], type: :producer_consumer

  @impl GenStage
  def handle_events(events, _from, [suffix]) do
    processed_events =
      events
      |> Enum.map(fn e -> "#{e}_#{suffix}" end)

    {:noreply, processed_events, [suffix]}
  end
end

defmodule ParallelGenStage.ConsA do
  use ElixirDrip.Pipeliner.Consumer, args: [:foo], type: :consumer

  @impl GenStage
  def handle_events(events, _from, [foo]) do
    for event <- events do
      Process.sleep(1000)

      IO.inspect({self(), foo, event})
    end

    # As a consumer we never emit events
    {:noreply, [], [foo]}
  end
end
