defmodule ElixirDrip.Behaviours.CacheSupervisor do
  @type id :: binary()
  @type content :: bitstring()
  @type reason :: tuple()

  @callback cache_for(id, content) :: {:ok, pid} | {:error, reason}
  @callback cache_content(id) :: content | nil
end
