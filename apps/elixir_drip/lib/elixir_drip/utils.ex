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
