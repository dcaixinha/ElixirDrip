defmodule ElixirDrip.Storage.Search do
  alias ElixirDrip.Storage.Supervisors.SlowCacheSupervisor, as: Cache

  def naive_search_for(media_ids, expression) when is_list(media_ids) do
    media_ids
    |> Enum.map(&search_for(&1, expression))
    |> Enum.into(%{})
  end

  defp search_for(media_id, expression) do
    raw_content_lines = Cache.cache_content(media_id)
                        |> String.split("\n")

    result = raw_content_lines
    |> Stream.with_index()
    |> Enum.reduce(
      [],
      fn({content, line}, accum) ->
         case found?(expression, content) do
           nil -> accum
           _   -> accum ++ [{line+1, content}]
         end
      end)

    {media_id, result}
  end

  def found?(expression, content) do
    regex = ~r/#{expression}/
    Regex.run(regex, content, return: :index)
  end
end
