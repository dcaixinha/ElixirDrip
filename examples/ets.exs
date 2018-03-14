alias ElixirDrip.Storage.Workers.SearchCacheWorker, as: SC
{:ok, sc} = SC.start_link

SC.cache_search_result("1", "media", "media id1")
SC.cache_search_result("1", "jose", "jose id1")
SC.cache_search_result("2", "media", "media id2")
SC.cache_search_result("4", "media", "media id4")
SC.cache_search_result("5", "media", "media id5")
SC.search_result_for("1", "media")
SC.search_result_for("2", "media")
SC.search_result_for("1", "zzz")
SC.all_search_results_for("1")
SC.all_search_results_for("2")
SC.all_search_results_for("3")

expired = :os.system_time(:seconds)
query_for_ids = :ets.fun2ms(fn {{media_id, search_expression}, {created_at, result}} when created_at < expired -> {media_id, search_expression} end)
[
  {{{:"$1", :"$2"}, {:"$3", :"$4"}}, [{:<, :"$3", {:const, 1518462860}}], [{{:"$1", :"$2"}}]}
]

query_for_values = :ets.fun2ms(fn {{media_id, search_expression}, {created_at, result}} when created_at < expired -> {created_at, result} end)
[
  {{{:"$1", :"$2"}, {:"$3", :"$4"}}, [{:<, :"$3", {:const, 1518462860}}], [{{:"$3", :"$4"}}]}
]
SC.cache_search_result("4", "media", "media id4")
{:ok, true}

:ets.select(:search_cache, query)
[{1518462562, "jose id1"}, {1518462513, "media id1"}, {1518462544, "media id2"}]

