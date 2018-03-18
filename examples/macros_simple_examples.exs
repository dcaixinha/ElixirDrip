defmodule Demo do
  defmacro simple(param) do
    IO.puts "Inside the Demo.simple/1 macro"
    IO.inspect param

    result = quote bind_quoted: [evaluated_param: param] do
      param_value = evaluated_param
      other_param_value = evaluated_param

      IO.puts "(injected into the caller context) param value is #{param_value}"
      :os.system_time(:seconds)
    end

    IO.puts "Demo.simple/1 result with unquoted param"
    IO.inspect result

    result
  end

  defmacro simple_module_level(param) do
    IO.puts "Inside the Demo.simple_module_level/1 macro"
    IO.inspect param

    y = "Y was set on the macro context"
    result = quote bind_quoted: [evaluated_param: param] do

      y = :set_on_macro
      def unquote(y)(), do: unquote(evaluated_param)
    end

    IO.puts "Demo.simple_module_level/1 result"
    IO.inspect result

    result
  end
end

defmodule Playground do
  import Demo

  y = :set_on_caller_module
  simple_module_level("out of do_something")

  def do_something do
    IO.puts "Inside the Playground.do_something/0 function"

    simple(5 == (25/5))
  end
end
