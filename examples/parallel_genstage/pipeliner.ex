defmodule ParallelGenStage.Pipeliner do
  @pipeliner_default_count 2
  @pipeliner_default_min_demand 44
  @pipeliner_default_max_demand 88

  # TODO: default opts like name, min_demand and max_demand
  # for each ProdConsumer|Consumer passed through __using__ options
  defmacro __using__(opts) do
    name = get_or_default(opts, :name, random_name(:pipeliner))
    default_count = get_or_default(opts, :count, @pipeliner_default_count)
    default_min_demand = get_or_default(opts, :min_demand, @pipeliner_default_min_demand)
    default_max_demand = get_or_default(opts, :max_demand, @pipeliner_default_max_demand)

    IO.puts "Starting Pipeliner: #{name}"
    quote do
      use Supervisor
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :default_count, [])
      Module.register_attribute(__MODULE__, :default_min_demand, [])
      Module.register_attribute(__MODULE__, :default_max_demand, [])
      @default_count unquote(default_count)
      @default_min_demand unquote(default_min_demand)
      @default_max_demand unquote(default_max_demand)

      def start_link() do
        Supervisor.start_link(__MODULE__, [], name: unquote(name))
      end
    end
  end

  defmacro start(producer, opts \\ []) do
    quote bind_quoted: [producer: producer, opts: opts] do
      opts = get_options_and_args(opts, @default_count, @default_min_demand, @default_max_demand)

      IO.puts "START: #{producer}, #{inspect(opts[:args])}, #{inspect(opts)}"
    end
  end

  defmacro step(producer_consumer, opts \\ []) do
    quote bind_quoted: [producer_consumer: producer_consumer, opts: opts] do
      opts = get_options_and_args(opts, @default_count, @default_min_demand, @default_max_demand)

      IO.puts "STEP: #{producer_consumer}, #{inspect(opts[:args])}, #{inspect(opts)}"
    end
  end

  defmacro finish(consumer, opts \\ []) do
    quote bind_quoted: [consumer: consumer, opts: opts] do
      opts = get_options_and_args(opts, @default_count, @default_min_demand, @default_max_demand)

      IO.puts "CONSUMER: #{consumer}, #{inspect(opts[:args])}, #{inspect(opts)}"
    end
  end

  def get_options_and_args(options, default_count, default_min_demand, default_max_demand) do
    result = [{:count, default_count},
              {:min_demand, default_min_demand},
              {:max_demand, default_max_demand}]
              |> Enum.reduce([], fn {key, default}, result ->
                Keyword.put(result, key, get_or_default(options, key, default))
              end)

    args = case options[:args] do
      nil  -> []
      args -> args
    end

    Keyword.put(result, :args, args)
  end

  defp get_or_default(options, _key, default \\ nil)
  defp get_or_default([], _key, default), do: default
  defp get_or_default(options, key, default) do
    case options[key] do
      nil   -> default
      value -> value
    end
  end

  defp random_name(name), do: Module.concat(name, random_suffix())
  defp random_suffix, do: :crypto.strong_rand_bytes(4) |> Base.encode16()
end
