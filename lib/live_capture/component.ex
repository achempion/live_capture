defmodule LiveCapture.Component do
  defmacro __using__(_) do
    quote do
      Module.register_attribute(__MODULE__, :capture, accumulate: true)
      Module.put_attribute(__MODULE__, :__captures__, %{})

      @on_definition LiveCapture.Component
      @before_compile LiveCapture.Component

      import LiveCapture.Component, only: [capture: 0, capture: 1, capture_all: 0]
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
      def __captures__ do
        @__captures__
      end
    end
  end

  def __on_definition__(env, _kind, name, args, _guards, _body) do
    capture = env.module |> Module.delete_attribute(:capture) |> List.first()

    capture_all = Module.get_attribute(env.module, :capture_all) && length(args) == 1

    if capture || capture_all do
      captures =
        Module.get_attribute(env.module, :__captures__)
        |> Map.update(name, capture || %{}, fn value -> Map.merge(value, capture || %{}) end)

      Module.put_attribute(env.module, :__captures__, captures)
    end
  end

  def list do
    apps = Application.get_env(:live_capture, :apps, [])
    apps = if Enum.empty?(apps), do: [:live_capture], else: apps
    include_live_capture? = Enum.member?(apps, :live_capture)

    apps
    |> Enum.flat_map(fn app ->
      case :application.get_key(app, :modules) do
        {:ok, modules} -> modules
        _ -> []
      end
    end)
    |> Enum.reject(fn module ->
      not include_live_capture? and
        module |> Atom.to_string() |> String.starts_with?("Elixir.LiveCapture")
    end)
    |> Enum.uniq()
    |> Enum.filter(fn module ->
      has_captures = module.__info__(:functions) |> Keyword.has_key?(:__captures__)

      has_captures && Enum.any?(module.__captures__)
    end)
  end

  def attributes(module, function, variant \\ nil) do
    default_attributes =
      module.__components__
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
      module.__captures__ |> Map.get(function, %{}) |> Map.get(:attributes, %{})

    variants = module.__captures__ |> Map.get(function, %{}) |> Map.get(:variants, [])

    variant_attributes =
      Keyword.get_lazy(variants, variant, fn ->
        variants |> Keyword.values() |> List.first() |> Kernel.||(%{})
      end)

    default_attributes |> Map.merge(default_capture_attributes) |> Map.merge(variant_attributes)
  end

  def attrs(module, function, variant \\ nil) do
    variants = module.__captures__ |> Map.get(function, %{}) |> Map.get(:variants, [])

    variant_config =
      if variant do
        Enum.find_value(variants, fn
          {name, cfg} when name == variant -> cfg
          _ -> nil
        end)
      else
        List.first(variants) |> Kernel.||({nil, nil}) |> elem(1)
      end ||
        %{}

    variant_config = variant_config |> Map.put_new(:attrs, %{})

    phoenix_component = Map.get(module.__components__, function, %{})

    attrs =
      Enum.reduce(phoenix_component[:attrs] || [], %{}, fn attr, acc ->
        cond do
          Map.has_key?(variant_config[:attrs], attr.name) ->
            Map.put(acc, attr.name, variant_config[:attrs][attr.name])

          true ->
            case attr do
              %{name: name, opts: [default: value]} ->
                Map.put(acc, name, value)

              %{name: name, opts: [examples: [value | _]]} ->
                Map.put(acc, name, value)

              _ ->
                acc
            end
        end
      end)

    Enum.reduce(variant_config[:attrs], attrs, fn {key, value}, acc ->
      Map.put_new(acc, key, value)
    end)
  end

  def slots(module, function, variant \\ nil) do
    variants = module.__captures__ |> Map.get(function, %{}) |> Map.get(:variants, [])
    phoenix_component = Map.get(module.__components__, function, %{})

    variant_config =
      if variant do
        Enum.find_value(variants, fn
          {name, cfg} when name == variant -> cfg
          _ -> nil
        end)
      else
        List.first(variants) |> Kernel.||({nil, nil}) |> elem(1)
      end ||
        %{}

    variant_config =
      variant_config
      |> Map.put_new(:attrs, %{})
      |> Map.put_new(:slots, %{})

    phoenix_component = Map.get(module.__components__, function, %{})

    Enum.reduce(phoenix_component[:slots] || [], %{}, fn slot, acc ->
      if Map.has_key?(variant_config[:slots], slot.name) do
        Map.put(
          acc,
          slot.name,
          normalize_slot_entries(slot.name, variant_config[:slots][slot.name])
        )
      else
        acc
      end
    end)
  end

  defp normalize_slot_entries(slot_name, entries) when is_list(entries) do
    Enum.map(entries, &build_slot_entry(slot_name, &1))
  end

  defp normalize_slot_entries(slot_name, entry) do
    [build_slot_entry(slot_name, entry)]
  end

  defp build_slot_entry(slot_name, %{} = entry) do
    {content, attrs} =
      if Map.has_key?(entry, :content) do
        {Map.get(entry, :content), Map.delete(entry, :content)}
      else
        {nil, entry}
      end

    build_slot_entry(slot_name, content, attrs)
  end

  defp build_slot_entry(slot_name, content) do
    build_slot_entry(slot_name, content, %{})
  end

  defp build_slot_entry(slot_name, content, attrs) do
    inner_block =
      case content do
        fun when is_function(fun, 1) ->
          fn changed, arg -> fun.(arg) end

        fun when is_function(fun, 0) ->
          fn _changed, _arg -> fun.() end

        _ ->
          normalized = normalize_slot_content(content)
          fn _changed, _arg -> normalized end
      end

    %{
      __slot__: slot_name,
      inner_block: inner_block
    }
    |> Map.merge(attrs)
  end

  defp normalize_slot_content(nil), do: []
  defp normalize_slot_content(content) when is_list(content), do: content
  defp normalize_slot_content(content), do: [to_string(content)]
end
