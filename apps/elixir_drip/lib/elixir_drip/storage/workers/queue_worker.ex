defmodule ElixirDrip.Storage.Workers.QueueWorker do
  use     GenServer
  require Logger

  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: queue_name(name))
  end

  def queue_name(name) do
    name = name
           |> Atom.to_string()
           |> String.capitalize()

    "#{__MODULE__}.#{name}"
    |> String.to_atom()
  end

  def init(queue) do
    Logger.debug("#{inspect(self())}: QueueWorker started.")

    {:ok, queue}
  end

  def dequeue(pid, no_items \\ 1), do: GenServer.call(pid, {:dequeue, no_items})

  def handle_call({:dequeue, _no_items}, _from, [] = queue), do: {:reply, queue, queue}
  def handle_call({:dequeue, no_items}, _from, queue) do
    {events, queue} = Enum.split(queue, no_items)

    Logger.debug("#{inspect(self())}: Will dequeue #{inspect(events)}. Now with #{length(queue)} items enqueued.")

    {:reply, events, queue}
  end

  def enqueue(pid, event), do: GenServer.cast(pid, {:enqueue, event})
  def handle_cast({:enqueue, event}, queue) do
    Logger.debug("#{inspect(self())}: Just enqueued #{inspect(event)}. Now with #{length(queue)+1} items enqueued.")

    {:noreply, queue ++ [event]}
  end
end
