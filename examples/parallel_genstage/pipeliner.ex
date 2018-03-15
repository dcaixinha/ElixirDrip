defmodule ParallelGenStage.Pipeliner do
  defmacro __using__(name: name) do
    quote do
      use Supervisor

      def start_link() do
        Supervisor.start_link(__MODULE__, [], name: unquote(name))
      end
    end
  end
end
