defmodule Z do
  import ElixirDrip.Chronometer

  def simple(za) do
    IO.puts("Simple: #{za}")
  end

  defchrono2 not_simple(ze) do
    IO.puts("Not simple: #{ze}")
  end

  defchrono2 not_simple_no_args do
    IO.puts("Not simple no args")
  end

  defchrono3 many_args(x, y, z \\ 2) do
    IO.puts("Many args")
    x + y + z
  end

  defchrono4 few_args(x, y \\ 5) do
    IO.puts("Few args")
    x + y
  end

  defmine funcy(z) do
    IO.puts z
    "xyy"
  end

  data = [foo: "1", bar: "2"]
  defkv data
end
