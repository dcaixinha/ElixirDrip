defmodule ElixirDrip.Utils.Benchmarks do
  alias ElixirDrip.Utils
  alias ElixirDrip.Storage.Search
  alias ElixirDrip.Storage.Supervisors.SlowCacheSupervisor, as: Cache

  def measured_naive_search(search_term \\ "Polk", media_items \\ 10), do: Utils.measure(fn -> naive_search(search_term, media_items) end)

  def naive_search(search_term \\ "Polk", media_items \\ 10) do
    1..media_items
    |> Enum.map(fn it ->
      content = File.read!("secrets/big.txt")
      id = to_string(it)
      Cache.cache_for(id, content)
      id
    end)
    |> Search.naive_search_for(search_term)
  end
end
