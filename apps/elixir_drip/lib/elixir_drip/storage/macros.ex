defmodule ElixirDrip.Storage.Macros do
  defmacro remaining_path_size(pwd_size, full_path) do

    quote do
      fragment("length(right(?, ?)) > 0", unquote(full_path), unquote(pwd_size))
    end
  end
end
