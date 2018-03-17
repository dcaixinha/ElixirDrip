defmodule ParallelGenStage.GuineaProducer do
  use GenStage

  def start_link(initial, name) do
    GenStage.start_link(__MODULE__, initial, name: name)
  end

  def init(counter), do: {:producer, counter}

  def handle_demand(demand, state) do
    events = Enum.to_list(state..(state + demand - 1))
    {:noreply, events, state + demand}
  end
end
