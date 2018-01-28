defmodule ElixirDrip.Storage.Supervisors.SlowCacheSupervisor do
  @behaviour ElixirDrip.Behaviours.CacheSupervisor

  require Logger
  alias   ElixirDrip.Storage.Supervisors.CacheSupervisor, as: RealCache

  def put(id, content) do
    Logger.debug("Spawning a slow cache for #{id}, content size: #{byte_size(content)} bytes.")

    RealCache.put(id, content)
  end

  def get(id) do
    Logger.debug("Fetching cached content for #{id}...")

    secs_to_nap = case Integer.parse(id) do
      {sleep_time, _} -> sleep_time
      _               -> 1
    end

    Process.sleep(secs_to_nap * 1000)
    RealCache.get(id)
  end

  def put_or_refresh(_id, _content) do
    # just to avoid getting a compiler warning
    :noop
  end

  def refresh(_id) do
    # just to avoid getting a compiler warning
    :noop
  end
end
