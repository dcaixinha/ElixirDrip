defmodule ElixirDrip.Chronometer do
  @moduledoc false
  alias ElixirDrip.Chronometer

  defmacro defchrono_v0(function_definition, do: body) do
    IO.puts "On defchrono_v0, function definition:"
    IO.inspect function_definition
    IO.puts "Body:"
    IO.inspect body

    quote do
      def unquote(function_definition) do
        unquote(body)
      end
    end
  end

  # works but doesn't have the function name
  defmacro defchrono_v1(function_definition, do: body) do
    IO.puts "On defchrono_v1, function definition:"
    IO.inspect function_definition

    quote do
      def unquote(function_definition) do
        Chronometer.run_and_measure(fn -> unquote(body) end)
      end
    end
  end

  # works but only has the function name
  defmacro defchrono_v2(function_definition, do: body) do
    {function, args} = Macro.decompose_call(function_definition)
    IO.puts "On defchrono_v2, function definition:"
    IO.inspect function_definition
    IO.puts "Function"
    IO.inspect function
    IO.puts "Arguments"
    IO.inspect args

    quote do
      def unquote(function_definition) do
        Chronometer.run_and_measure(unquote(function), fn -> unquote(body) end)
      end
    end
  end

  # apparently works, but if we use with default args, it breaks
  defmacro defchrono_v3(function_definition, do: body) do
    {function, args} = Macro.decompose_call(function_definition)
    IO.puts "On defchrono_v3"
    IO.inspect function_definition
    IO.puts "Function"
    IO.inspect function
    IO.puts "Arguments"
    IO.inspect args

    ast_to_return = quote do
      def unquote(function_definition) do
        signature =
          Chronometer.pretty_signature(__MODULE__, unquote(function), unquote(args))

        Chronometer.run_and_measure(signature, fn -> unquote(body) end)
      end
    end

    IO.puts "Returning"
    ast_to_return
    |> Macro.to_string()
    |> IO.puts()

    ast_to_return
  end

  # works with every kind of function signatures, uses Macro.to_string
  # to see what are we injecting
  defmacro defchrono_v4(function_definition, do: body) do
    {function, args} = Macro.decompose_call(function_definition)
    arity = length(args)
    IO.puts "On defchrono_v4"
    IO.inspect function_definition
    IO.puts "Function"
    IO.inspect function
    IO.puts "Arguments"
    IO.inspect args

    ast_to_return = quote do
      def unquote(function_definition) do
        signature =
          Chronometer.pretty_signature(__MODULE__, unquote(function), unquote(arity))

        Chronometer.run_and_measure(signature, fn -> unquote(body) end)
      end
    end

    IO.puts "Returning"
    ast_to_return
    |> Macro.to_string()
    |> IO.puts()

    ast_to_return
  end

  defmacro defchrono_v5_nok(function_definition, do: body) do
    {function, args} = Macro.decompose_call(function_definition)
    arity = length(args)
    IO.puts "On defchrono_v5_nok"
    IO.inspect function_definition
    IO.inspect Macro.escape(function_definition)
    IO.puts "Function"
    IO.inspect function
    IO.inspect Macro.escape(function)
    IO.puts "Arguments"
    IO.inspect args
    IO.inspect Macro.escape(args)

    ast_to_return = quote bind_quoted: [
      function_definition: function_definition,
      body: body,
      function: function,
      arity: arity
    ] do
      def unquote(function_definition) do
        signature =
          Chronometer.pretty_signature(__MODULE__, unquote(function), unquote(arity))

        Chronometer.run_and_measure(signature, fn -> unquote(body) end)
      end
    end

    IO.puts "defchrono_v5_nok result with bind_quoted"
    IO.puts Macro.to_string ast_to_return

    ast_to_return
  end

  # with bind_quoted, we still have to unquote to delay the evaluation of the
  # function_definition, body, function and arity
  # We Macro.escape all variables to bind the respective quoted value for each variable
  # (bind_quoted expects all variables to bind to be quoted (in their AST representation))
  defmacro defchrono_v5(function_definition, do: body) do
    {function, args} = Macro.decompose_call(function_definition)
    arity = length(args)
    IO.puts "On defchrono_v5"
    IO.inspect function_definition
    IO.puts "Escaped function_definition"
    IO.inspect Macro.escape(function_definition)
    IO.puts "Function"
    IO.inspect function
    IO.puts "Arguments"
    IO.inspect args

    ast_to_return = quote bind_quoted: [
      function_definition: function_definition,
      body: Macro.escape(body),
      function: function,
      arity: arity
    ] do
      def unquote(function_definition) do
        signature =
          Chronometer.pretty_signature(__MODULE__, unquote(function), unquote(arity))

        Chronometer.run_and_measure(signature, fn -> unquote(body) end)
      end
    end

    IO.puts "Returning"
    ast_to_return
    |> Macro.to_string()
    |> IO.puts()

    ast_to_return
  end

  defmacro defmine(function_def, do: body) do
    IO.puts "Defmine result"
    IO.inspect function_def
    IO.inspect body

    # DON'T WORK
    result = quote bind_quoted: [function_def: Macro.escape(function_def),
                        body: Macro.escape(body)] do
    # WORKS
    # result = quote bind_quoted: [function_def: Macro.escape(function_def),
    #                     body: Macro.escape(body)] do
    # WORKS but needs unquote everywhere as previous example
    # result = quote do
      def unquote(function_def), do: unquote(body)
      # def unquote(function_def), do: unquote(body)
      # def unquote(function_def) do
      #   IO.inspect unquote(body)
      #   "hey"
      # end
    end
    IO.puts "defmine result quote/unquoted/bind_quoted:"
    IO.puts Macro.to_string result
    result
  end

  defmacro defkv(kv) do
    quote bind_quoted: [kv: kv] do
      Enum.each kv, fn {k, v} ->
        def unquote(k)(), do: unquote(Macro.escape(v))
      end
    end
  end

  def run_and_measure(to_measure) do
    {time_µs, result} = :timer.tc(to_measure)
    IO.puts "Run in #{time_µs} µs"

    result
  end

  def run_and_measure(to_run, to_measure) do
    {time_µs, result} = :timer.tc(to_measure)
    IO.puts "Took #{time_µs} µs to run #{to_run}"

    result
  end

  def pretty_signature(module, function, args) when is_list(args) do
    module = module
             |> Atom.to_string()
             |> String.replace_leading("Elixir.", "")

    "#{module}.#{function}/#{length(args)}"
  end

  def pretty_signature(module, function, arity) do
    module = module
             |> Atom.to_string()
             |> String.replace_leading("Elixir.", "")

    "#{module}.#{function}/#{arity}"
  end
end
