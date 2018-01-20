defmodule ElixirDrip.Storage.Search do
  @moduledoc false

  require Logger
  alias   ElixirDrip.Storage.Supervisors.SlowCacheSupervisor, as: Cache

  def naive_search_for(media_ids, expression) when is_list(media_ids) do
    media_ids
    |> Enum.map(&search_for(&1, expression))
    |> Enum.into(%{})
  end

  def task_search_for(media_ids, expression, timeout \\ 20_000) when is_list(media_ids) do
    media_ids
    |> Enum.map(&Task.async(__MODULE__, :search_for, [&1, expression]))
    |> Enum.map(&Task.await(&1, timeout))
  end

  def task_search_for_verbose(media_ids, expression) when is_list(media_ids) do
    media_ids
    |> Enum.map(fn media_id ->
      t = Task.async(__MODULE__, :search_for, [media_id, expression])
      Logger.debug("#{inspect(self())} Spawned a search for #{media_id}, PID: #{inspect(t.pid)}")

      t
    end)
    |> Enum.map(fn task ->
      Logger.debug("#{inspect(self())} Will now wait for task PID: #{inspect(task.pid)}")
      {media_id, results} = Task.await(task, 20_000)
      Logger.debug("#{inspect(self())} Task PID: #{inspect(task.pid)} returned with #{length(results)} for #{media_id}")

      results
    end)
  end

  def task_async_search_for(media_ids, expression, concurrency \\ 4, timeout \\ 20) when is_list(media_ids) do
    media_ids
    |> Task.async_stream(__MODULE__, :search_for, [expression], max_concurrency: concurrency, timeout: timeout)
    |> Enum.map(&elem(&1, 1))
    |> Enum.into(%{})
  end

  def search_for(media_id, expression) do
    raw_content_lines = media_id
                        |> Cache.get()
                        |> String.split("\n")

    result = raw_content_lines
    |> Stream.with_index()
    |> Enum.reduce(
      [],
      fn({content, line}, accum) ->
         case found?(expression, content) do
           nil -> accum
           _   -> accum ++ [{line + 1, content}]
         end
      end)

    {media_id, result}
  end

  def found?(expression, content) do
    regex = ~r/#{expression}/
    Regex.run(regex, content, return: :index)
  end
end
