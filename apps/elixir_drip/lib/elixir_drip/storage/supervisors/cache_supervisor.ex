defmodule ElixirDrip.Storage.Supervisors.CacheSupervisor do
  @behaviour ElixirDrip.Behaviours.CacheSupervisor

  use   Supervisor
  alias ElixirDrip.Storage.Workers.CacheWorker

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    cache_worker_spec =
      Supervisor.child_spec(
        CacheWorker,
        start: {CacheWorker, :start_link, []},
        restart: :temporary
      )

    Supervisor.init([cache_worker_spec], strategy: :simple_one_for_one)
  end

  def put(id, content) when is_binary(id) and is_bitstring(content),
    do: Supervisor.start_child(__MODULE__, [id, content])

  def refresh(id) when is_binary(id) do
    case find_cache(id) do
      nil -> nil
      pid -> CacheWorker.refresh(pid)
    end
  end

  def put_or_refresh(id, content) when is_binary(id) and is_bitstring(content) do
    case refresh(id) do
      nil    -> put(id, content)
      result -> result
    end
  end

  def get(id) when is_binary(id) do
    case find_cache(id) do
      nil -> nil
      pid -> CacheWorker.get_media(pid)
    end
  end

  def find_cache(id) when is_binary(id) do
    GenServer.whereis(CacheWorker.name_for(id))
  end
end
