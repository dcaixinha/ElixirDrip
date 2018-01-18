defmodule ElixirDrip.Utils.Benchmarks do
  @moduledoc false

  alias ElixirDrip.Utils
  alias ElixirDrip.Storage.Search
  alias ElixirDrip.Storage.Supervisors.SlowCacheSupervisor, as: Cache

  def measured_naive_search(search_term \\ "Polk", media_items \\ 10), do: Utils.measure(fn -> naive_search(search_term, media_items) end)

  def naive_search(search_term \\ "Polk", media_items \\ 10) do
    media_items
    |> prepare_cache()
    |> Search.naive_search_for(search_term)
  end

  def measured_task_search(search_term \\ "Polk", media_items \\ 10, timeout), do: Utils.measure(fn -> task_search(search_term, media_items, timeout) end)

  def task_search(search_term \\ "Polk", media_items \\ 10, timeout) do
    media_items
    |> prepare_cache()
    |> Search.task_search_for(search_term, timeout)
  end

  def measured_task_async_search(search_term \\ "Polk", media_items \\ 10, concurrency, timeout), do: Utils.measure(fn -> task_async_search(search_term, media_items, concurrency, timeout) end)

  def task_async_search(search_term \\ "Polk", media_items \\ 10, concurrency, timeout) do
    media_items
    |> prepare_cache()
    |> Search.task_async_search_for(search_term, concurrency, timeout)
  end

  def prepare_cache(media_items) do
    1..media_items
    |> Enum.map(fn it ->
      content = File.read!("secrets/big.txt")
      id = to_string(it)
      Cache.cache_for(id, content)
      id
    end)
  end
end
