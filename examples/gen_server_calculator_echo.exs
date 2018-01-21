defmodule Calculator do
  use GenServer

  def handle_call({:mult, number}, _from, state) do
    {:reply, number*5, state}
  end
end
{:ok, calc} = GenServer.start_link(Calculator, [])
GenServer.call(calc, {:mult, 7})

defmodule Echo do
  def echoes() do
    receive do
      message ->
        IO.puts "Echo on #{inspect(self())}: #{inspect(message)}"
    end

    echoes()
  end
end

echo = Process.spawn(&Echo.echoes/0 , [])

GenServer.call(echo, {:hello, :echo})

GenServer.cast(echo, {:hi_again, :echo})
