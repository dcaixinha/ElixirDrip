defmodule ParallelGenStage.Supervisor do
  alias ParallelGenStage.{
    Producer,
    ProducerConsumer,
    Consumer
  }
  use   Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Supervisor.init([
      worker(Producer, [0]),
      worker(ProducerConsumer, ["A"], id: :pc_a),
      worker(ProducerConsumer, ["B"], id: :pc_b),
      worker(ProducerConsumer, ["C"], id: :pc_c),
      worker(Consumer, ["ConsumerX", ["A", "B", "C"]], id: :c_x),
      worker(Consumer, ["ConsumerY", ["A", "B", "C"]], id: :c_y)
    ],
    strategy: :rest_for_one,
    name: __MODULE__
    )
  end
end
