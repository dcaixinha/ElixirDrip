defmodule ElixirDrip.Storage.Workers.SearchCacheWorker do
  @moduledoc false

  use     GenServer
  require Logger

  @search_cache :search_cache

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.debug("#{inspect(self())}: SearchCacheWorker started.")
    search_cache = :ets.new(@search_cache, [:named_table, :set, :protected])

    {:ok, search_cache}
  end

  def search_result_for(media_id, search_expression) do
    case :ets.lookup(@search_cache, {media_id, search_expression}) do
      []                      -> nil
      [{_key, search_result}] -> search_result
    end
  end

  def all_search_result_for(media_id) do
    case :ets.match_object(@search_cache, {{media_id, :"_"}, :"_"}) do
      []          -> nil
      all_objects -> all_objects |> Enum.map(&elem(&1, 1))
    end
  end

  def cache_search_result(media_id, search_expression, result) do
    GenServer.call(__MODULE__, {:put, media_id, search_expression, result})
  end

  def delete_cache_search(media_id, search_expression) do
    GenServer.call(__MODULE__, {:delete, media_id, search_expression})
  end

  def handle_call({:put, media_id, search_expression, result}, _from, search_cache) do
    result = :ets.insert_new(search_cache, {{media_id, search_expression}, result})

    {:reply, {:ok, result}, search_cache}
  end

  def handle_call({:delete, media_id, search_expression}, _from, search_cache) do
    result = :ets.delete(search_cache, {media_id, search_expression})

    {:reply, {:ok, result}, search_cache}
  end
end
