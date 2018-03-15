defmodule ParallelGenStage.GuineaPigSupervisor do
  alias ParallelGenStage.Pipeliner
  alias ParallelGenStage.GuineaProducer, as: Producer
  alias ParallelGenStage.GuineaProducerConsumer, as: ProducerConsumer
  alias ParallelGenStage.GuineaConsumer, as: Consumer

  use Pipeliner, name: :zaza

  # start [0], count: 1

  def init(_) do
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

    to_start = [
      producer_workers,
      producer_consumer_workers_lvl1,
      producer_consumer_workers_lvl2,
      consumer_workers
    ] |> List.flatten()

    Supervisor.init(
      to_start,
      strategy: :rest_for_one,
      name: __MODULE__
    )
  end
end
