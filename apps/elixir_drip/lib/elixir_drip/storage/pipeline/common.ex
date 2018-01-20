defmodule ElixirDrip.Storage.Pipeline.Common do
  @moduledoc false

  def stage_name(stage, name) do
    name = name
           |> Atom.to_string()
           |> String.capitalize()

    Module.concat(stage, name)
  end
end
