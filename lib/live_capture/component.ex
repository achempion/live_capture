defmodule LiveCapture.Component do
  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :capture, accumulate: true)
      Module.put_attribute(__MODULE__, :__captures__, %{})

      @on_definition LiveCapture.Component
      @before_compile LiveCapture.Component

      import LiveCapture.Component, only: [capture: 0, capture: 1]
    end
  end

  defmacro capture(attrs \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :capture,
        LiveCapture.Component.normalize_capture_opts(unquote(attrs))
      )
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def __captures__ do
        @__captures__
      end
    end
  end

  def __on_definition__(env, _kind, name, _args, _guards, _body) do
    capture = Module.delete_attribute(env.module, :capture) |> List.first()

    if capture do
      quote do
        Module.put_attribute(__MODULE__, :list, MapSet.put(@list, env.module))
      end

      captures = Module.get_attribute(env.module, :__captures__) |> Map.put(name, capture)

      Module.put_attribute(env.module, :__captures__, captures)
    end
  end

  def list do
    {:ok, list} = :application.get_key(:live_capture, :modules)
    list |> Enum.filter(&(&1.__info__(:functions) |> Keyword.has_key?(:__captures__)))
  end

  def normalize_capture_opts(opts) when is_list(opts), do: Map.new(opts)
  def normalize_capture_opts(opts) when is_map(opts), do: opts
  def normalize_capture_opts(_), do: %{}
end
