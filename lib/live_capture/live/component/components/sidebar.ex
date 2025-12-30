defmodule LiveCapture.Component.Components.Sidebar do
  use Phoenix.Component
  use LiveCapture.Component

  attr :modules, :list,
    required: true,
    examples: [[LiveCapture.Component.Components.Example]]

  attr :component, :map,
    default: nil,
    examples: [
      %{
        module: LiveCapture.Component.Components.Example,
        function: :hello_world,
        attrs: [%{name: :title, opts: [examples: ["Earth"]]}]
      }
    ]

  capture()

  def show(assigns) do
    ~H"""
    <.section
      :for={module <- @modules}
      module={module}
      component={@component}
      is_selected={@component[:module] == module}
    />
    """
  end

  attr :module, :any, required: true
  attr :component, :map, required: true
  attr :is_selected, :boolean, required: true

  defp section(assigns) do
    ~H"""
    <section class={[
      "py-1 px-2 border-l-2 hover:border-primary hover:bg-primary/5",
      @is_selected && "bg-primary/5 border-primary"
    ]}>
      <.module_title module={@module} is_selected={@is_selected} />
      <.functions_list :if={@is_selected} module={@module} component={@component} />
    </section>
    """
  end

  attr :module, :any, required: true
  attr :is_selected, :boolean, required: true

  defp module_title(%{is_selected: true} = assigns) do
    ~H"""
    <div class="text-primary">
      <%= @module %>
    </div>
    """
  end

  defp module_title(%{is_selected: false} = assigns) do
    ~H"""
    <div>
      <.link navigate={"/components/#{@module}/#{Enum.at(@module.__captures__, 0) |> elem(0)}"}>
        <%= @module %>
      </.link>
    </div>
    """
  end

  attr :module, :any, required: true
  attr :component, :map, required: true

  defp functions_list(assigns) do
    assings = assign(assigns, selected_class: "")

    ~H"""
    <ul class="ml-4 py-2">
      <li :for={{capture, _} <- @module.__captures__}>
        <.link
          navigate={"/components/#{@module}/#{capture}"}
          class={[
            "block border-l-2 px-3 cursor-pointer",
            (capture == @component[:function] &&
               "border-primary text-primary") ||
              "hover:text-slate-900 hover:border-primary border-slate-300 text-slate-700"
          ]}
        >
          <%= capture %>/<%= attr_count(@module, capture) %>
        </.link>
      </li>
    </ul>
    """
  end

  defp attr_count(module, capture) do
    module.__components__
    |> Map.get(capture, %{})
    |> Map.get(:attrs, [])
    |> length()
  end
end
