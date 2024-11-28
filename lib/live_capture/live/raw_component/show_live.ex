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

    {:noreply, assign(socket, attrs: attrs)}
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
end
