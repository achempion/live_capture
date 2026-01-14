defmodule LiveCapture.RawComponent.ShowLive do
  use LiveCapture.Web, :live_view

  def render(%{module: nil} = assigns),
    do: ~H"""
    <div class="p-4 text-red-600">Module doesn't exist</div>
    """

  def render(%{function: nil} = assigns),
    do: ~H"""
    <div class="p-4 text-red-600">Function doesn't exist</div>
    """

  def render(assigns) do
    ~H"""
    {LiveCapture.Component.render(__ENV__, @module, @function, @variant)}
    """
  end

  def mount(params, _session, socket) do
    module =
      LiveCapture.Component.list(socket.assigns.component_loaders)
      |> Enum.find(&(to_string(&1) == params["module"]))

    function =
      module &&
        module.__live_capture__[:captures]
        |> Map.keys()
        |> Enum.find(&(to_string(&1) == params["function"]))

    {:ok,
     assign(socket,
       module: module,
       function: function,
       variant: normalize_variant(params["variant"])
     )}
  end

  def handle_event(_name, _params, socket) do
    {:noreply, socket}
  end

  defp normalize_variant(nil), do: nil
  defp normalize_variant(""), do: nil

  defp normalize_variant(variant_param) do
    String.to_existing_atom(variant_param)
  rescue
    ArgumentError -> nil
  end
end
