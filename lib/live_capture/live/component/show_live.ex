defmodule LiveCapture.Example do
  use Phoenix.Component
  use LiveCapture.Component

  capture()

  def hello(assigns) do
    ~H"""
    <p>Hello world!</p>
    """
  end

  attr :title, :string, examples: ["53"]
  capture()

  def hello2(assigns) do
    ~H"""
    <p>Hello world2!</p>
    """
  end
end

defmodule LiveCapture.Component.ShowLive do
  use LiveCapture.Web, :live_view
  alias LiveCapture.Component.Components

  def mount(_, _, socket) do
    modules = LiveCapture.Component.list()

    {:ok, assign(socket, modules: modules, component: nil)}
  end

  def handle_params(%{"module" => module, "function" => function}, _, socket) do
    module =
      Enum.find(
        socket.assigns.modules,
        &(to_string(&1) == module)
      )

    function =
      module.__captures__ |> Map.keys() |> Enum.find(&(to_string(&1) == function))

    phoenix_component = module.__components__[function] || %{}

    {:noreply,
     assign(socket,
       component: %{module: module, function: function, attrs: phoenix_component[:attrs]}
     )}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <div class="flex min-h-svh">
      <div class="w-96 border-r">
        <div class="text-xl">Components</div>
        <div :for={module <- @modules}>
          <%= module %>
          <.link
            :for={{capture, _} <- module.__captures__}
            navigate={"/components/#{module}/#{capture}"}
            class="block py-4 hover:bg-slate-200 cursor-pointer"
          >
            <%= capture %>
          </.link>
        </div>
      </div>
      <div class="flex-1 flex flex-col">
        <div class="flex-1">
          <iframe
            :if={@component[:function]}
            class="h-full w-full"
            src={"/raw/components/#{@component[:module]}/#{@component[:function]}"}
          >
          </iframe>
        </div>
        <div :if={@component} class="border-t">
          <Components.Attribute.list :if={@component[:attrs]} attrs={@component[:attrs]} />
        </div>
      </div>
    </div>
    """
  end
end
