defmodule ParallelGenStage.GuineaSupervisor do
  alias ElixirDrip.Pipeliner
  alias ParallelGenStage.GuineaProducer, as: Producer
  alias ParallelGenStage.GuineaProducerConsumer, as: ProducerConsumer
  alias ParallelGenStage.GuineaConsumer, as: Consumer

  use Pipeliner,
    name: :guinea_pipeline, min_demand: 4, max_demand: 8

  start Producer,
    args: [275], count: 2
  step ProducerConsumer,
    args: ["Z"], count: 3, min_demand: 1, max_demand: 10
  step ProducerConsumer,
    args: ["W"], count: 3, min_demand: 1, max_demand: 3
  finish Consumer,
    args: ["JOZe", "Rico"], count: 2
end
