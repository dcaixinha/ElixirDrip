defmodule ElixirDrip.ProcessRegister do
  @moduledoc false

  require Logger
  use GenServer
  import Kernel, except: [send: 2]

  @name __MODULE__

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def init([]) do
    Logger.debug("#{inspect(self())} Started the ElixirDrip process register.")

    {:ok, %{}}
  end

  def register_name(name, pid),
    do: GenServer.call(@name, {:register_name, {name, pid}})

  def unregister_name(name),
    do: GenServer.call(@name, {:unregister_name, name})

  def whereis_name(name),
    do: GenServer.call(@name, {:whereis_name, name})

  def send(name, message),
    do: GenServer.call(@name, {:send, {name, message}})

  def handle_info(message, register) do
    Logger.debug("#{inspect(self())} Just got the following message: #{inspect(message)}")

    # TODO: We should pattern-match here on {:DOWN, reference, :process, pid, reason} messages
    # and deregister the pid. To make this process faster, we could store a map
    # using the reference returned by `.monitor/1` or pid as keys

    {:noreply, register}
  end

  def handle_call({:register_name, {name, pid}}, _from, register) do
    Logger.debug("#{inspect(self())} Registering name '#{inspect(name)}' for #{inspect(pid)}.")

    {reply, register} = case Map.has_key?(register, name) do
      true -> {:no, register}
      _    ->
        reference = Process.monitor(pid)
        {:yes, Map.put(register, name, {reference, pid})}
    end

    {:reply, reply, register}
  end

  def handle_call({:unregister_name, name}, _from, register) do
    Logger.debug("#{inspect(self())} Unregistering name '#{inspect(name)}'.")
    case Map.fetch(register, name) do
      {:ok, {reference, _pid}} ->
        Process.demonitor(reference)
      _ -> nil
    end

    register = Map.delete(register, name)

    {:reply, :ok, register}
  end

  def handle_call({:whereis_name, name}, _from, register) do

    reply = case Map.get(register, name) do
      nil         -> :undefined
      {_ref, pid} -> pid
    end

    Logger.debug("#{inspect(self())} Searching for name '#{inspect(name)}', found #{inspect(reply)}.")

    {:reply, reply, register}
  end

  def handle_call({:send, {name, message}}, _from, register) do
    reply = case Map.get(register, name) do
      {_ref, pid} when is_pid(pid) ->
        Kernel.send(pid, message)
        pid

      _ -> raise ":badarg, #{inspect({name, message})}"
    end

    Logger.debug("#{inspect(self())} Sending #{inspect(message)} to '#{inspect(name)}', resulted in  #{inspect(reply)}.")

    {:reply, reply, register}
  end
end
