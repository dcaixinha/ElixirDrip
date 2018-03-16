defmodule ParallelGenStage.Pipeliner do
  # TODO: default opts like name, min_demand and max_demand
  # for each ProdConsumer|Consumer passed through __using__ options
  defmacro __using__(name: name) do
    quote do
      use Supervisor
      import unquote(__MODULE__)

      def start_link() do
        Supervisor.start_link(__MODULE__, [], name: unquote(name))
      end
    end
  end

  defmacro start(producer, opts \\ []) do
    quote bind_quoted: [producer: producer, opts: opts] do
      IO.puts "START: #{producer}, #{inspect(opts[:args])}, #{inspect(opts)}"
    end
  end

  defmacro step(producer_consumer, opts \\ []) do
    quote bind_quoted: [producer_consumer: producer_consumer, opts: opts] do
      IO.puts "STEP: #{producer_consumer}, #{inspect(opts[:args])}, #{inspect(opts)}"
    end
  end

  defmacro finish(consumer, opts \\ []) do
    quote bind_quoted: [consumer: consumer, opts: opts] do
      IO.puts "CONSUMER: #{consumer}, #{inspect(opts[:args])}, #{inspect(opts)}"
    end
  end
end
