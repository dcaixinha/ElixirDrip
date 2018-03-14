alias ElixirDrip.Storage.Workers.FlexibleSearchCacheWorker, as: FSC
{:ok, fsc} = FSC.start_link(:dets)

FSC.cache_search_result("1", "media", "media id1")
FSC.cache_search_result("1", "jose", "jose id1")
FSC.cache_search_result("2", "media", "media id2")
FSC.cache_search_result("4", "media", "media id4")
FSC.cache_search_result("5", "media", "media id5")
FSC.search_result_for("1", "media")
FSC.search_result_for("2", "media")
FSC.search_result_for("1", "zzz")
FSC.all_search_results_for("1")
FSC.all_search_results_for("2")
FSC.all_search_results_for("3")
