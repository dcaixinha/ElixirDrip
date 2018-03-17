defmodule ElixirDrip.Pipeliner.Consumer do
  import ElixirDrip.Pipeliner

  defmacro __using__(opts) do
    type = get_or_default(opts, :type)
    if type not in [:producer_consumer, :consumer] do
      raise ArgumentError, ":type needs to be one of :producer_consumer or :consumer"
    end

    args = get_or_default(opts, :args, [])
    optional_args = create_args(__MODULE__, args)
    required_args = create_args(__MODULE__, [:name, :sub_options])

    optional_and_subscription_args = optional_args ++ create_args(__MODULE__, [:sub_options])

    function_args = optional_args ++ required_args

    optional_args = case length(optional_args) == 1 do
      true -> Enum.at(optional_args, 0)
      _    -> optional_args
    end

    quote do
      use GenStage

      def start_link(unquote_splicing(function_args)) do
        GenStage.start_link(
          __MODULE__, unquote(optional_and_subscription_args), name: name)
      end

      def init([unquote_splicing(optional_and_subscription_args)]) do
        {unquote(type), unquote(optional_args), subscribe_to: sub_options}
      end
    end
  end

  defp create_args(_, []), do: []
  defp create_args(module, arg_names),
    do: Enum.map(arg_names, &Macro.var(&1, module))
end
