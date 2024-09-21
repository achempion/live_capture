defmodule CaptureUI.Example do
  use Phoenix.Component
  use CaptureUI.Component

  capture()

  def hello(assigns) do
    ~H"""
    <p>Hello world!</p>
    """
  end

  capture()

  def hello2(assigns) do
    ~H"""
    <p>Hello world2!</p>
    """
  end
end

defmodule CaptureUI.Main.ShowLive do
  use CaptureUI.Web, :live_view

  def mount(_, _, socket) do
    modules = CaptureUI.Component.list()

    {:ok, assign(socket, modules: modules, component: nil)}
  end

  def handle_event("component:show", params, socket) do
    module =
      Enum.find(
        socket.assigns.modules,
        &(to_string(&1) == params["module"])
      )

    {:noreply, assign(socket, component: %{module: module, function: params["function"]})}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-svh">
      <div class="w-96 border-r">
        <div class="text-xl">Components</div>
        <div :for={module <- @modules}>
          <%= module %>
          <div
            :for={{capture, _} <- module.__captures__}
            class="py-4 hover:bg-slate-200 cursor-pointer"
            phx-click="component:show"
            phx-value-module={module}
            phx-value-function={capture}
          >
            <%= capture %>
          </div>
        </div>
      </div>
      <div class="flex-1 flex flex-col">
        <div class="flex-1">
          <iframe
            :if={@component[:function]}
            class="h-full w-full"
            src={"/components/#{@component[:module]}/#{@component[:function]}"}
          >
          </iframe>
        </div>
        <div class="border-t">Attributes</div>
      </div>
    </div>
    """
  end
end
