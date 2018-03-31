defmodule ParallelGenStage.TestC do
  alias ElixirDrip.Pipeliner

  alias ParallelGenStage.ProdC
  alias ParallelGenStage.ProdConsC
  alias ParallelGenStage.ConsC

  use Pipeliner,
    name: :guinea_pipeline_c, min_demand: 4, max_demand: 8

  start ProdC,
    args: [275], count: 2
  step ProdConsC,
    args: ["W"], count: 3, min_demand: 1, max_demand: 10
  step ProdConsC,
    args: ["Z"], count: 3, min_demand: 1, max_demand: 3
  finish ConsC,
    args: ["JOZe"], count: 2
end


defmodule ParallelGenStage.ProdC do
  use ElixirDrip.Pipeliner.Producer, args: [:initial]

  @impl ElixirDrip.Pipeliner.Producer
  def prepare_state([i]) do
    IO.puts "ProdC: Preparing #{i}"

    i
  end

  @impl GenStage
  def handle_demand(demand, counter) do
    events = Enum.to_list(counter..(counter + demand - 1))

    {:noreply, events, counter + demand}
  end
end

defmodule ParallelGenStage.ProdConsC do
  use ElixirDrip.Pipeliner.Consumer, args: [:suffix], type: :producer_consumer

  @impl ElixirDrip.Pipeliner.Consumer
  def prepare_state([s]) do
    IO.puts "ProdConsC: Preparing #{s}"

    s
  end

  @impl GenStage
  def handle_events(events, _from, suffix) do
    processed_events =
      events
      |> Enum.map(fn e -> "#{e}_#{suffix}" end)

    {:noreply, processed_events, suffix}
  end
end

defmodule ParallelGenStage.ConsC do
  use ElixirDrip.Pipeliner.Consumer, args: [:foo], type: :consumer

  @impl ElixirDrip.Pipeliner.Consumer
  def prepare_state([foo]) do
    IO.puts "ConsC: Preparing #{foo}"

    foo
  end

  @impl GenStage
  def handle_events(events, _from, foo) do
    for event <- events do
      Process.sleep(1000)

      IO.inspect({self(), foo, event})
    end

    # As a consumer we never emit events
    {:noreply, [], foo}
  end
end
