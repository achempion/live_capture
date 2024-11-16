defmodule CaptureUI.Component do
  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :capture, accumulate: true)
      Module.put_attribute(__MODULE__, :__captures__, %{})

      @on_definition CaptureUI.Component
      @before_compile CaptureUI.Component

      import CaptureUI.Component, only: [capture: 0]
    end
  end

  defmacro capture do
    quote do
      Module.put_attribute(__MODULE__, :capture, %{})
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
    {:ok, list} = :application.get_key(:capture_ui, :modules)
    list |> Enum.filter(&(&1.__info__(:functions) |> Keyword.has_key?(:__captures__)))
  end
end
