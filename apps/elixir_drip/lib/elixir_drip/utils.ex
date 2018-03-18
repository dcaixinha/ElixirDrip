defmodule ElixirDrip.Utils do
  require Logger

  def generate_timestamp do
    DateTime.utc_now()
    |> DateTime.to_iso8601(:basic)
    |> String.split(".")
    |> hd
  end

  def measure(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
    |> log_time()
  end

  def run_and_measure(function), do: :timer.tc(function)

  def log_time(time) do
    Logger.debug("Took: #{time} secs")
  end

  def safe_measure(function) do
    safe_function(function)
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end

  def safe_function(function) do
    fn ->
      try do
        function.()
      rescue
        error -> Logger.error "Ended function with:\n#{inspect(error)}"
      end
    end
  end

  def ast_without_metadata({op, _metadata, value}) when is_tuple(value), do: {op, ast_without_metadata(value)}
  def ast_without_metadata({op, _metadata, list}) when is_list(list), do: {op, ast_without_metadata(list)}
  def ast_without_metadata([value|rest]), do: [ast_without_metadata(value)] ++ ast_without_metadata(rest)
  def ast_without_metadata([]), do: []
  def ast_without_metadata({op, _metadata, value}), do: {op, value}
  def ast_without_metadata(ast), do: ast

  def spawn_ticker(), do: spawn(__MODULE__.Ticker, :loop, [])

  defmodule Ticker do
    def loop() do
      receive do
        :start ->
          Process.send_after(self(), {:tick, 0}, 1000)
        {:tick, ticks} ->
          Logger.debug "Seconds elapsed: #{ticks+1} secs"
          Process.send_after(self(), {:tick, ticks+1}, 1000)
      end
      loop()
    end
  end
end
