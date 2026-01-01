defmodule LiveCapture.RawComponent.ShowLive do
  use LiveCapture.Web, :live_view

  def mount(params, session, socket) do
    module = LiveCapture.Component.list() |> Enum.find(&(to_string(&1) == params["module"]))

    function =
      module.__captures__ |> Map.keys() |> Enum.find(&(to_string(&1) == params["function"]))

    {:ok, assign(socket, module: module, function: function)}
  end

  def handle_params(params, uri, socket) do
    %{"custom_params" => custom_params} = URI.parse(uri).query |> Plug.Conn.Query.decode()
    custom_params = if custom_params == "", do: %{}, else: custom_params

    phoenix_component = socket.assigns.module.__components__[socket.assigns.function] || %{}

    attrs =
      Enum.reduce(phoenix_component[:attrs] || [], %{}, fn attr, acc ->
        custom_value = custom_params[to_string(attr.name)]

        if custom_value == nil do
          case attr do
            %{name: name, opts: [examples: [example | _]]} ->
              Map.put(acc, name, example)

            _ ->
              acc
          end
        else
          Map.put(acc, attr.name, custom_value)
        end
      end)

    slots = capture_slots(socket.assigns.module, socket.assigns.function)
    {:noreply, assign(socket, attrs: Map.merge(slots, attrs))}
  end

  def render(assigns) do
    ~H"""
    <%= Phoenix.LiveView.TagEngine.component(
      Function.capture(@module, @function, 1),
      @attrs,
      {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
    ) %>
    """
  end

  defp capture_slots(module, function) do
    module.__captures__
    |> Map.get(function, %{})
    |> Map.get(:slots, %{})
    |> Enum.map(fn {slot_name, content} ->
      {slot_name, normalize_slot_entries(slot_name, content)}
    end)
    |> Map.new()
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
