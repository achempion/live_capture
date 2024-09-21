defmodule CaptureUI.Component.ShowLive do
  use CaptureUI.Web, :live_view

  def mount(params, _, socket) do
    module = CaptureUI.Component.list() |> Enum.find(&(to_string(&1) == params["module"]))

    function =
      module.__captures__ |> Map.keys() |> Enum.find(&(to_string(&1) == params["function"]))

    {:ok, assign(socket, module: module, function: function, attrs: [])}
  end

  def render(assigns) do
    ~H"""
    <%= apply(@module, @function, [@attrs]) %>
    """
  end
end
