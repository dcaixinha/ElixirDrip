defmodule ElixirDrip.Storage.Supervisors.SlowCacheSupervisor do
  @behaviour ElixirDrip.Behaviours.CacheSupervisor

  require Logger
  alias   ElixirDrip.Storage.Supervisors.CacheSupervisor, as: RealCache

  @quick_nap 2_000

  def cache_for(id, content) do
    Logger.debug("Spawning a slow cache for #{id}, content size: #{byte_size(content)} bytes.")

    RealCache.cache_for(id, content)
  end

  def cache_content(id) do
    Logger.debug("Fetching cached content for #{id}...")

    Process.sleep(@quick_nap)
    RealCache.cache_content(id)
  end
end
