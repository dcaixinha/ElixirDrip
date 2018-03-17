defmodule ElixirDrip.Pipeliner.Producer do
  import ElixirDrip.Pipeliner

  defmacro __using__(opts) do
    args = get_or_default(opts, :args, [])
    prepare_function = get_or_default(opts, :prepare_state)

    optional_args = create_args(__MODULE__, args)
    required_args = create_args(__MODULE__, [:name])

    function_args = optional_args ++ required_args

    optional_args = case length(optional_args) == 1 do
      true -> Enum.at(optional_args, 0)
      _    -> optional_args
    end

    quote do
      use GenStage

      def start_link(unquote_splicing(function_args)) do
        GenStage.start_link(__MODULE__, unquote(optional_args), name: name)
      end

      def init(args) do
        args = prepare_args(unquote(prepare_function), args)

        {:producer, args}
      end

      defp prepare_args(nil, args), do: args
      defp prepare_args(function, args) do
        apply(__MODULE__, function, [args])
      end
    end
  end

  defp create_args(_, []), do: []
  defp create_args(module, arg_names),
    do: Enum.map(arg_names, &Macro.var(&1, module))
end
