defmodule ParallelGenStage.Pipeliner do
  # TODO: REMOVE THESE ALIASES
  alias ParallelGenStage.Pipeliner
  alias ParallelGenStage.GuineaProducer, as: Producer
  alias ParallelGenStage.GuineaProducerConsumer, as: ProducerConsumer
  alias ParallelGenStage.GuineaConsumer, as: Consumer

  import Supervisor.Spec

  @pipeliner_default_count 4
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

      Module.register_attribute(__MODULE__, :pipeline_steps, accumulate: true)

      def start_link() do
        Supervisor.start_link(__MODULE__, [], name: unquote(name))
      end

      @before_compile unquote(__MODULE__)

      def init(_) do

        producer_step = get_pipeline_steps() |> Enum.at(0)
        IO.puts "PRODUCER specs:"
        {producer_names, producer_worker_specs} = get_worker_specs(producer_step)
        IO.inspect(producer_names)
        IO.inspect(producer_worker_specs)

        # -----------------

        producer_consumer_step = get_pipeline_steps() |> Enum.at(1)
        IO.puts "PRODUCER CONSUMER(1) specs:"

        {
          producer_consumer_1_names,
          producer_consumer_worker_1_specs
        } = producer_consumer_step
            |> Enum.concat(names_to_subscribe: producer_names)
            |> get_worker_specs()

        IO.inspect(producer_consumer_1_names)
        IO.inspect(producer_consumer_worker_1_specs)

        # ------------------

        producer_consumer_step = get_pipeline_steps() |> Enum.at(2)
        IO.puts "PRODUCER CONSUMER(2) specs:"

        {
          producer_consumer_2_names,
          producer_consumer_worker_2_specs
        } = producer_consumer_step
            |> Enum.concat(names_to_subscribe: producer_consumer_1_names)
            |> get_worker_specs()

        IO.inspect(producer_consumer_2_names)
        IO.inspect(producer_consumer_worker_2_specs)

        # ------------------

        consumer_step = get_pipeline_steps() |> Enum.at(3)
        IO.puts "CONSUMER specs:"

        {
          consumer_names,
          consumer_worker_specs
        } = consumer_step
            |> Enum.concat(names_to_subscribe: producer_consumer_2_names)
            |> get_worker_specs()

        IO.inspect(consumer_names)
        IO.inspect(consumer_worker_specs)

        workers_to_start =
          producer_worker_specs ++ producer_consumer_worker_1_specs ++ producer_consumer_worker_2_specs ++ consumer_worker_specs

        # workers_to_start = get_worker_specs()
        #                    |> List.flatten()

        Supervisor.init(
          workers_to_start,
          strategy: :rest_for_one,
          name: __MODULE__
        )
      end
    end
  end

  defmacro __before_compile__(_environment) do
    quote do
      def get_pipeline_steps() do
        @pipeline_steps |> Enum.reverse()
      end
    end
  end

  defmacro start(producer, opts \\ []) do
    quote bind_quoted: [producer: producer, opts: opts] do
      opts = get_options_and_args(opts, @default_count, @default_min_demand, @default_max_demand)

      @pipeline_steps [producer: producer, args: opts[:args], options: opts[:options]]
      IO.puts "START: #{producer}, #{inspect(opts)}"
    end
  end

  defmacro step(producer_consumer, opts \\ []) do
    quote bind_quoted: [producer_consumer: producer_consumer, opts: opts] do
      opts = get_options_and_args(opts, @default_count, @default_min_demand, @default_max_demand)

      @pipeline_steps [producer_consumer: producer_consumer, args: opts[:args], options: opts[:options]]
      IO.puts "STEP: #{producer_consumer}, #{inspect(opts)}"
    end
  end

  defmacro finish(consumer, opts \\ []) do
    quote bind_quoted: [consumer: consumer, opts: opts] do
      opts = get_options_and_args(opts, @default_count, @default_min_demand, @default_max_demand)

      @pipeline_steps [consumer: consumer, args: opts[:args], options: opts[:options]]
      IO.puts "CONSUMER: #{consumer}, #{inspect(opts)}"
    end
  end

  def get_worker_specs() do
    producer_initials = [0, 1000]
    producer_workers = producer_initials
                       |> Enum.map(fn initial ->
                         worker(Producer, [initial], id: String.to_atom("p_" <> to_string(initial)))
                       end)

    producer_consumer_suffixes_lvl1 = ["G", "H", "I"]

    producer_consumer_subscriptions_lvl1 = producer_initials
                             |> Enum.map(fn initial ->
                               {
                                 Module.concat(Producer, to_string(initial)),
                                 min_demand: 1, max_demand: 5
                               }
                             end)

    producer_consumer_workers_lvl1 = producer_consumer_suffixes_lvl1
                                |> Enum.map(fn suffix ->
                                  worker(
                                    ProducerConsumer,
                                    [suffix, producer_consumer_subscriptions_lvl1],
                                    id: String.to_atom("pc1_" <> suffix)
                                  )
                                end)

    producer_consumer_suffixes_lvl2 = ["A", "B", "C"]

    product_consumer_subscriptions_lvl2 = producer_consumer_suffixes_lvl1
                             |> Enum.map(fn suffix ->
                               {
                                 Module.concat(ProducerConsumer, suffix),
                                 min_demand: 1, max_demand: 5
                               }
                             end)

    producer_consumer_workers_lvl2 = producer_consumer_suffixes_lvl2
                                |> Enum.map(fn suffix ->
                                  worker(
                                    ProducerConsumer,
                                    [suffix, product_consumer_subscriptions_lvl2],
                                    id: String.to_atom("pc2_" <> suffix)
                                  )
                                end)

    consumer_subscriptions = producer_consumer_suffixes_lvl2
                             |> Enum.map(fn suffix ->
                               {
                                 Module.concat(ProducerConsumer, suffix),
                                 min_demand: 1, max_demand: 5
                               }
                             end)

    consumer_workers = ["X", "Y"]
                       |> Enum.map(fn suffix ->
                         worker(
                           Consumer,
                           ["Consumer" <> suffix, consumer_subscriptions],
                           id: String.to_atom("c_" <> suffix)
                         )
                       end)

    [
      producer_workers,
      producer_consumer_workers_lvl1,
      producer_consumer_workers_lvl2,
      consumer_workers
    ]
  end

  def get_worker_specs(producer: producer, args: args, options: options) do
    {count, options} = Keyword.pop(options, :count)

    1..count
    |> Enum.map(fn _ ->
      name = random_name(producer)
      {name, worker(producer, args ++ [name], id: Atom.to_string(name))}
    end)
    |> Enum.unzip()
  end

  def get_worker_specs(producer_consumer: producer_consumer,
                       args: args, options: options,
                       names_to_subscribe: names_to_subscribe),
    do: get_worker_specs_with_subscriptions(producer_consumer,
                         args: args, options: options,
                         names_to_subscribe: names_to_subscribe)

  def get_worker_specs(consumer: consumer,
                       args: args, options: options,
                       names_to_subscribe: names_to_subscribe),
    do: get_worker_specs_with_subscriptions(consumer,
                         args: args, options: options,
                         names_to_subscribe: names_to_subscribe)

  def get_worker_specs_with_subscriptions(consumer,
                       args: args, options: options,
                       names_to_subscribe: names_to_subscribe) do

    {count, options} = Keyword.pop(options, :count)

    subscriptions = names_to_subscribe
                    |> Enum.map(fn to_subscribe ->
                      {to_subscribe, options}
                    end)

    1..count
    |> Enum.map(fn _ ->
      name = random_name(consumer)
      args = args ++ [name, subscriptions]

      {name, worker(consumer, args, id: Atom.to_string(name))}
    end)
    |> Enum.unzip()
  end

  def get_options_and_args(opts, default_count, default_min_demand, default_max_demand) do

    options_and_args = fill_options_and_args(opts, default_count, default_min_demand, default_max_demand)

    options = Keyword.drop(options_and_args, [:args])

    options_and_args
    |> Enum.filter(fn {k,_} -> k == :args end)
    |> Keyword.put(:options, options)
  end

  def fill_options_and_args(options, default_count, default_min_demand, default_max_demand) do
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
