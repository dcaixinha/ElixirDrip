defmodule ElixirDrip.Utils do
  def generate_timestamp do
    DateTime.utc_now()
    |> DateTime.to_iso8601(:basic)
    |> String.split(".")
    |> hd
  end

  def measure(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end
