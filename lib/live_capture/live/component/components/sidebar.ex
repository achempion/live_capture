defmodule LiveCapture.Component.Components.Sidebar do
  use Phoenix.Component
  use LiveCapture.LiveCaptureDemo

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

  attr :live_capture_path, :string, required: true, examples: ["/"]

  capture()

  def show(assigns) do
    ~H"""
    <.section
      :for={module <- @modules}
      module={module}
      component={@component}
      live_capture_path={@live_capture_path}
      is_selected={@component[:module] == module}
    />
    """
  end

  attr :module, :any, required: true
  attr :component, :map, required: true
  attr :is_selected, :boolean, required: true
  attr :live_capture_path, :string, required: true

  defp section(assigns = %{is_selected: true}) do
    ~H"""
    <section class={[
      "py-1 pl-2 pr-4 border-l-2 ",
      @is_selected && "bg-primary/5 border-primary"
    ]}>
      <div class="text-primary">
        {@module |> to_string() |> String.replace_prefix("Elixir.", "")}
      </div>
      <.functions_list
        :if={@is_selected}
        module={@module}
        component={@component}
        live_capture_path={@live_capture_path}
      />
    </section>
    """
  end

  defp section(assigns = %{is_selected: false}) do
    ~H"""
    <.link
      navigate={"#{@live_capture_path}/components/#{@module}/#{Enum.at(@module.__live_capture__()[:captures], 0) |> elem(0)}"}
      class="block py-1 pl-2 pr-4 border-l-2 hover:border-primary hover:bg-primary/5 hover:text-primary"
    >
      {@module |> to_string() |> String.replace_prefix("Elixir.", "")}
    </.link>
    """
  end

  attr :module, :any, required: true
  attr :component, :map, required: true
  attr :live_capture_path, :string, required: true

  defp functions_list(assigns) do
    ~H"""
    <ul class="ml-4 py-2">
      <.function
        :for={{capture, config} <- @module.__live_capture__()[:captures]}
        module={@module}
        capture={capture}
        attr_count={attr_count(@module, capture)}
        variants={Keyword.keys(config[:variants] || [])}
        is_selected={capture == @component[:function]}
        selected_variant={@component[:variant]}
        live_capture_path={@live_capture_path}
      />
    </ul>
    """
  end

  attr :module, :any, required: true
  attr :capture, :any, required: true
  attr :attr_count, :integer, required: true
  attr :variants, :list, default: []
  attr :is_selected, :boolean, required: true
  attr :selected_variant, :any
  attr :live_capture_path, :string, required: true

  defp function(%{is_selected: true} = assigns) do
    ~H"""
    <li>
      <div class="block border-l-2 border-primary px-3 cursor-pointer text-primary">
        {@capture}/{@attr_count}
      </div>

      <ul :if={Enum.any?(@variants)} class="pt-1 pb-2">
        <li :for={variant <- @variants}>
          <.link
            navigate={"#{@live_capture_path}/components/#{@module}/#{@capture}/#{variant}"}
            class={[
              "group flex items-center gap-2 px-3 cursor-pointer",
              variant == @selected_variant &&
                "text-primary",
              variant != @selected_variant &&
                "text-slate-700 hover:text-primary"
            ]}
          >
            <span class={[
              "text-primary font-md text-xl leading-none",
              variant == @selected_variant && "opacity-100",
              variant != @selected_variant && "opacity-0 group-hover:opacity-100"
            ]}>
              &bull;
            </span>
            {variant}
          </.link>
        </li>
      </ul>
    </li>
    """
  end

  defp function(%{is_selected: false} = assigns) do
    ~H"""
    <li>
      <.link
        navigate={"#{@live_capture_path}/components/#{@module}/#{@capture}"}
        class="block border-l-2 px-3 cursor-pointer hover:text-primary hover:border-primary border-slate-300 text-slate-700"
      >
        {@capture}/{@attr_count}
      </.link>
    </li>
    """
  end

  defp attr_count(module, capture) do
    module.__components__()
    |> Map.get(capture, %{})
    |> Map.get(:attrs, [])
    |> length()
  end
end
