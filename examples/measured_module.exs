defmodule MeasuredModule do
  import ElixirDrip.Chronometer

  defchrono_v5 slow_square(x \\ 3) do
    Process.sleep(2000)
    x * x
  end

  [a: %{x: 1}, b: %{y: 9}] |> defkv()

  # defchrono_v3 slow_times(x, y) do
  #   Process.sleep(2000)
  #   x * y
  # end

  # defchrono_v3 slow_times(x, y, z) do
  #   Process.sleep(2000)
  #   x * y * z
  # end
end
