defmodule ElixirDrip.Storage.Search do
  @moduledoc false

  require Logger
  alias   ElixirDrip.Storage.Supervisors.SlowCacheSupervisor, as: Cache

  def naive_search_for(media_ids, expression) when is_list(media_ids) do
    media_ids
    |> Enum.map(&search_for(&1, expression))
    |> Enum.into(%{})
  end

  def task_search_for(media_ids, expression, timeout \\ 10_000) when is_list(media_ids) do
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
      {media_id, results} = Task.await(task, 10_000)
      Logger.debug("#{inspect(self())} Task PID: #{inspect(task.pid)} returned with #{length(results)} result(s) for #{media_id}")

      results
    end)
  end

  def task_stream_search_for(media_ids, expression, concurrency \\ 4, timeout \\ 10_000) when is_list(media_ids) do
    options = [max_concurrency: concurrency, timeout: timeout]

    media_ids
    |> Task.async_stream(__MODULE__, :search_for, [expression], options)
    |> Enum.map(&elem(&1, 1))
    |> Enum.into(%{})
  end

  def safe_task_stream_search_for(media_ids, expression, concurrency \\ 4, timeout \\ 10_000) when is_list(media_ids) do
    options = [max_concurrency: concurrency, timeout: timeout, on_timeout: :kill_task]

    media_ids
    |> Task.async_stream(__MODULE__, :search_for, [expression], options)
    |> Enum.map(&elem(&1, 1))
    |> Enum.reject(&(&1 == :timeout))
    |> Enum.into(%{})
  end

  def search_for(media_id, expression) do
    raw_content_lines = media_id
                        |> Cache.get()
                        |> elem(1)
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

  # data for the Flow examples

  def users do
    [
      %{id: 1, name: "andre_albuquerque", domain: "elixir.pt"},
      %{id: 2, name: "daniel_caixinha", domain: "elixir.pt"},
      %{id: 3, name: "jose_valim", domain: "elixir.br"},
      %{id: 4, name: "joe_armstrong", domain: "erlang.uk"},
      %{id: 5, name: "robert_virding", domain: "erlang.se"},
      %{id: 6, name: "mike_williams", domain: "erlang.wls"},
      %{id: 7, name: "jose_lusquinos", domain: "panda.pt"},
      %{id: 8, name: "atenas", domain: "meow.cat"},
      %{id: 9, name: "billy_boy", domain: "woof.dog"},
    ]
  end

  def custom_hash_partition_media() do
    [
      generate_media(1, 3),
      generate_media(2, 2),
      generate_media(3, 1),
      generate_media(4, 3),
      generate_media(5, 4),
      generate_media(6, 3),
    ]
  end

  def set_full_name(%{name: name} = user) do
    full_name = name
                |> String.split("_")
                |> Enum.map(&String.capitalize(&1))
                |> Enum.join(" ")

    Map.put(user, :full_name, full_name)
  end

  def set_country(%{domain: domain} = user) do
    country = domain
              |> String.split(".")
              |> Enum.reverse()
              |> Enum.at(0)
              |> String.upcase()

    Map.put(user, :country, country)
  end

  def set_preferences(%{domain: domain} = user) do
    preferences = domain
              |> String.split(".")
              |> Enum.at(0)

    Map.put(user, :preferences, preferences)
  end

  def random_media(how_many, max_users) do
    1..how_many
    |> Enum.map(fn i ->
      user = :rand.uniform(max_users)
      generate_media(i, user)
    end)
  end

  defp generate_media(id, user_id) do
    possible_extensions = [".bmp", ".jpg", ".png", ".mp3", ".md", ".doc", ".pdf"]

    file_name = 10
                |> :crypto.strong_rand_bytes()
                |> Base.encode32()
                |> String.downcase()

    %{
      id: id,
      user_id: user_id,
      file_name: file_name <> random_from(possible_extensions),
      file_size: :rand.uniform(10_000)
    }
  end

  defp random_from([]), do: nil
  defp random_from(collection) do
    index = :rand.uniform(length(collection) - 1)
    Enum.at(collection, index)
  end
end
