defmodule CaptureUI.RawComponent.ShowLive do
  use CaptureUI.Web, :live_view

  def mount(params, _, socket) do
    module = CaptureUI.Component.list() |> Enum.find(&(to_string(&1) == params["module"]))

    function =
      module.__captures__ |> Map.keys() |> Enum.find(&(to_string(&1) == params["function"]))

    phoenix_component = module.__components__[function] || %{}

    attrs =
      Enum.reduce(phoenix_component[:attrs] || [], %{}, fn
        %{name: name, opts: [examples: [example | _]]}, acc ->
          acc
          |> Map.put(name, example)

        _, acc ->
          acc
      end)

    {:ok, assign(socket, module: module, function: function, attrs: attrs)}
  end

  def render(assigns) do
    ~H"""
    <%= apply(@module, @function, [@attrs]) %>
    """
  end
end
