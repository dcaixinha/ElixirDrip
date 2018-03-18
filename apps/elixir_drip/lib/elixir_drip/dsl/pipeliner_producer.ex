defmodule ElixirDrip.Pipeliner.Producer do
  import ElixirDrip.Pipeliner

  defmacro __using__(opts) do
    args = get_or_default(opts, :args, [])
    prepare_function = get_or_default(opts, :prepare_state)

    optional_args = create_args(__MODULE__, args)
    required_args = create_args(__MODULE__, [:name])

    function_args = optional_args ++ required_args

    quote do
      use GenStage
      import unquote(__MODULE__)

      def start_link(unquote_splicing(function_args)) do
        GenStage.start_link(__MODULE__, unquote(optional_args), name: name)
      end

      def init([unquote_splicing(optional_args)]) do
        args = prepare_args(__MODULE__, unquote(prepare_function), unquote(optional_args))

        {:producer, args}
      end

    end
  end

  def prepare_args(_module, nil, [args]), do: args
  def prepare_args(_module, nil, args), do: args
  def prepare_args(module, function, args) do
    # apply always receives an argument list
    args = List.flatten([args])

    apply(module, function, args)
  end

  defp create_args(_, []), do: []
  defp create_args(module, arg_names),
    do: Enum.map(arg_names, &Macro.var(&1, module))
end
