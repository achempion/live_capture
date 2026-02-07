defmodule LiveCapture.Component do
  alias LiveCapture.Attribute

  defmodule Config do
    defmacro __using__(_) do
      quote do
        import LiveCapture.Component.Config, only: [breakpoints: 1, root_layout: 1, plugs: 1]

        @breakpoints []
        @root_layout {LiveCapture.Layouts, :root}
        @plugs []

        @before_compile LiveCapture.Component.Config
      end
    end

    defmacro breakpoints(list) do
      quote do
        Module.put_attribute(
          __MODULE__,
          :breakpoints,
          unquote(list)
        )
      end
    end

    defmacro root_layout(layout) do
      quote do
        Module.put_attribute(
          __MODULE__,
          :root_layout,
          unquote(layout)
        )
      end
    end

    defmacro plugs(list) do
      quote do
        Module.put_attribute(
          __MODULE__,
          :plugs,
          unquote(list)
        )
      end
    end

    defmacro __before_compile__(_env) do
      quote do
        def breakpoints(), do: @breakpoints
        def root_layout(), do: @root_layout
        def plugs(), do: @plugs
      end
    end
  end

  defmacro __using__(_) do
    quote do
      use LiveCapture.Component.Config

      defmacro __using__(opts) do
        loader_module = __MODULE__

        quote bind_quoted: [loader_module: loader_module] do
          Module.register_attribute(__MODULE__, :capture, accumulate: true)

          Module.put_attribute(__MODULE__, :__live_capture__, %{
            captures: %{},
            loader: loader_module
          })

          @on_definition LiveCapture.Component
          @before_compile LiveCapture.Component

          import LiveCapture.Component, only: [capture: 0, capture: 1, capture_all: 0]
        end
      end
    end
  end

  defmacro capture(attrs \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :capture,
        Map.new(unquote(attrs))
      )
    end
  end

  defmacro capture_all() do
    quote do
      Module.put_attribute(
        __MODULE__,
        :capture_all,
        true
      )
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def __live_capture__() do
        @__live_capture__
      end
    end
  end

  def __on_definition__(env, _kind, function_name, args, _guards, _body) do
    live_capture = Module.get_attribute(env.module, :__live_capture__)

    capture_config = env.module |> Module.delete_attribute(:capture) |> List.first()
    capture_all = Module.get_attribute(env.module, :capture_all) && length(args) == 1

    if capture_config || capture_all do
      captures =
        live_capture[:captures]
        |> Map.put_new(function_name, %{})
        |> Map.update!(function_name, &Map.merge(&1, capture_config || %{}))

      Module.put_attribute(
        env.module,
        :__live_capture__,
        Map.put(live_capture, :captures, captures)
      )
    end
  end

  def slot_names(module, function) do
    module.__components__()
    |> Map.get(function, %{})
    |> Map.get(:slots, [])
    |> Enum.map(& &1.name)
    |> maybe_implicit_slot_names(module, function)
  end

  defp maybe_implicit_slot_names([], module, function) do
    for {key, value} <- attributes(module, function),
        (is_map(value) and is_map_key(value, :inner_block)) or
          (is_list(value) and match?([%{inner_block: _} | _], value)),
        do: key
  end

  defp maybe_implicit_slot_names(list, _, _), do: list

  def render(env, module, function, variant \\ nil, conn_assigns \\ %{}) do
    attributes =
      module
      |> attributes(function, variant)
      |> resolve_conn_assigns(conn_assigns)

    slot_keys = slot_names(module, function)

    attributes =
      Enum.reduce(slot_keys, attributes, fn key, acc ->
        value = attributes[key]

        slot =
          cond do
            is_map(value) -> normalize_slot(key, value, attributes, module)
            is_list(value) -> Enum.map(value, &normalize_slot(key, &1, attributes, module))
            true -> normalize_slot(key, %{inner_block: value}, attributes, module)
          end

        Map.put(acc, key, slot)
      end)

    Phoenix.LiveView.TagEngine.component(
      Function.capture(module, function, 1),
      attributes,
      {env.module, env.function, env.file, env.line}
    )
  end

  defp normalize_slot(slot_key, slot_value, attributes, module) do
    slot_value
    |> Map.put(:__slot__, slot_key)
    |> Map.replace(:inner_block, fn _, _ ->
      if is_binary(slot_value.inner_block) do
        module
        |> LiveCapture.LiveRender.as_heex(slot_value.inner_block, attributes)
        |> Phoenix.HTML.raw()
      else
        slot_value.inner_block
      end
    end)
  end

  def list(component_loaders) do
    loader_set = MapSet.new(component_loaders)

    component_loaders
    |> Enum.flat_map(fn loader ->
      case Application.get_application(loader) do
        nil -> []
        app -> Application.spec(app, :modules) || []
      end
    end)
    |> Enum.uniq()
    |> Enum.filter(fn module ->
      Code.ensure_loaded?(module) &&
        function_exported?(module, :__live_capture__, 0) &&
        module.__live_capture__()[:captures] != %{} &&
        module.__live_capture__()[:loader] in loader_set
    end)
  end

  def attributes(module, function, variant \\ nil) do
    default_attributes =
      module.__components__()
      |> Map.get(function, %{})
      |> Map.get(:attrs, [])
      |> Enum.reduce(%{}, fn attr, acc ->
        value =
          case attr do
            %{opts: [examples: [example | _]]} -> example
            %{opts: [default: default]} -> default
            _ -> nil
          end

        Map.put(acc, attr.name, value)
      end)

    default_capture_attributes =
      module.__live_capture__()[:captures] |> Map.get(function, %{}) |> Map.get(:attributes, %{})

    variants =
      module.__live_capture__()[:captures] |> Map.get(function, %{}) |> Map.get(:variants, [])

    variant_attributes =
      Keyword.get_lazy(variants, variant, fn ->
        variants |> Keyword.values() |> List.first() |> Kernel.||(%{})
      end)

    default_attributes |> Map.merge(default_capture_attributes) |> Map.merge(variant_attributes)
  end

  defp resolve_conn_assigns(attributes, conn_assigns) do
    Enum.reduce(attributes, %{}, fn {key, value}, acc ->
      Map.put(acc, key, Attribute.resolve(value, conn_assigns))
    end)
  end
end
