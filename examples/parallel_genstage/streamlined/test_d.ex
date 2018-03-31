defmodule ParallelGenStage.TestD do
  alias ElixirDrip.Pipeliner

  alias ParallelGenStage.ProdD
  alias ParallelGenStage.ProdConsD
  alias ParallelGenStage.ConsD

  use Pipeliner,
    name: :guinea_pipeline_d, min_demand: 4, max_demand: 8

  start ProdD,
    args: [275, "hi there"], count: 2
  step ProdConsD,
    args: ["W", "not needed"], count: 3, min_demand: 1, max_demand: 10
  step ProdConsD,
    args: ["Z", "ups, just lookin' around"], count: 3, min_demand: 1, max_demand: 3
  finish ConsD,
    args: ["JOZe", "Rico"], count: 2
end


defmodule ParallelGenStage.ProdD do
  use ElixirDrip.Pipeliner.Producer, args: [:initial, :dont_care]

  @impl ElixirDrip.Pipeliner.Producer
  def prepare_state([i, d]) do
    IO.puts "ProdD: Preparing #{i} and #{d}"

    i
  end

  @impl GenStage
  def handle_demand(demand, counter) do
    events = Enum.to_list(counter..(counter + demand - 1))

    {:noreply, events, counter + demand}
  end
end

defmodule ParallelGenStage.ProdConsD do
  use ElixirDrip.Pipeliner.Consumer, args: [:suffix, :not_needed], type: :producer_consumer

  @impl ElixirDrip.Pipeliner.Consumer
  def prepare_state([s, n]) do
    IO.puts "ProdConsD: Preparing #{s} and #{n}"

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

defmodule ParallelGenStage.ConsD do
  use ElixirDrip.Pipeliner.Consumer, args: [:foo, :bar], type: :consumer

  @impl ElixirDrip.Pipeliner.Consumer
  def prepare_state([foo, bar]) do
    IO.puts "ConsD: Preparing #{foo} and #{bar}"

    [foo, bar]
  end

  @impl GenStage
  def handle_events(events, _from, [foo, bar]) do
    for event <- events do
      Process.sleep(1000)

      IO.inspect({self(), foo, bar, event})
    end

    # As a consumer we never emit events
    {:noreply, [], [foo, bar]}
  end
end
