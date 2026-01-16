defmodule LiveCapture.Component.ShowLive do
  use LiveCapture.Web, :live_view
  alias LiveCapture.Component.Components

  def mount(_, session, socket) do
    modules = LiveCapture.Component.list(socket.assigns.component_loaders)

    {:ok,
     assign(
       socket,
       modules: modules,
       component: nil,
       breakpoint_options: [],
       frame_configuration: %{"breakpoint" => nil},
       csp_style_nonce: session["csp_style_nonce"]
     )}
  end

  def handle_params(
        %{"module" => module, "function" => function, "variant" => variant},
        _,
        socket
      ) do
    assign_component(socket, module, function, variant)
  end

  def handle_params(%{"module" => module, "function" => function}, _, socket) do
    assign_component(socket, module, function, nil)
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  defp assign_component(socket, module_param, function_param, variant_param) do
    module = Enum.find(socket.assigns.modules, &(to_string(&1) == module_param))

    if module do
      function =
        module.__live_capture__()[:captures]
        |> Map.keys()
        |> Enum.find(&(to_string(&1) == function_param))

      phoenix_component = module.__components__()[function] || %{}

      variants =
        module.__live_capture__()[:captures]
        |> Map.get(function, %{})
        |> Map.get(:variants, [])
        |> Keyword.keys()

      selected_variant =
        cond do
          variant_param && variant_param in Enum.map(variants, &to_string/1) ->
            String.to_existing_atom(variant_param)

          variants != [] ->
            List.first(variants)

          true ->
            nil
        end

      breakpoints = module.__live_capture__()[:loader].breakpoints()

      {:noreply,
       assign(socket,
         breakpoints: breakpoints,
         breakpoint_options: Enum.map(breakpoints, &to_string(elem(&1, 0))),
         component: %{
           module: module,
           function: function,
           attrs: phoenix_component[:attrs],
           slots: phoenix_component[:slots],
           variants: variants,
           variant: selected_variant,
           custom_params: %{}
         }
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("change", params, socket) do
    custom_params =
      Enum.reduce(socket.assigns.component.attrs, %{}, fn attr, acc ->
        key = to_string(attr.name)

        if params[key] == nil do
          acc
        else
          Map.put(acc, key, params[key])
        end
      end)

    component = Map.put(socket.assigns.component, :custom_params, custom_params)

    {:noreply, assign(socket, :component, component)}
  end

  def handle_event("frame_configuration:change", params, socket) do
    configuration =
      params["frame_configuration"]
      |> Enum.map(&{elem(&1, 0), (elem(&1, 1) != "" && elem(&1, 1)) || nil})
      |> Map.new()

    {:noreply, assign(socket, frame_configuration: configuration)}
  end

  defp iframe_width(breakpoints, frame_configuration) do
    breakpoint = frame_configuration["breakpoint"]
    breakpoint_value = breakpoint && breakpoints[String.to_existing_atom(breakpoint)]

    breakpoint_value
  end

  def render(assigns) do
    payload = Plug.Conn.Query.encode(%{custom_params: assigns.component[:custom_params] || %{}})

    url =
      if assigns.component[:variant] do
        "#{assigns.live_capture_path}/raw/components/#{assigns.component[:module]}/#{assigns.component[:function]}/#{assigns.component[:variant]}?#{payload}"
      else
        "#{assigns.live_capture_path}/raw/components/#{assigns.component[:module]}/#{assigns.component[:function]}?#{payload}"
      end

    iframe_width = iframe_width(assigns[:breakpoints], assigns[:frame_configuration])
    assigns = assign(assigns, iframe_src: url, iframe_width: iframe_width)

    ~H"""
    <Components.Layout.show>
      <:sidebar>
        <Components.Sidebar.show
          modules={@modules}
          component={@component}
          live_capture_path={@live_capture_path}
        />
      </:sidebar>

      <:header>
        <.form
          :let={f}
          for={to_form(@frame_configuration)}
          as={:frame_configuration}
          phx-change="frame_configuration:change"
          class="ml-auto flex gap-4 items-end"
        >
          <Components.Form.options field={f[:breakpoint]} options={@breakpoint_options} />
        </.form>
      </:header>

      <:render>
        <style :if={@iframe_width} nonce={@csp_style_nonce}>
          <%= "#live-capture-frame { width: #{@iframe_width}; }" %>
        </style>
        <iframe
          :if={@component[:function]}
          id="live-capture-frame"
          class="h-full w-full bg-white absolute"
          src={@iframe_src}
        >
        </iframe>
      </:render>

      <:docs>
        <Components.Docs.show :if={@component} component={@component} />
      </:docs>

      <:attributes>
        <form :if={@component && @component[:attrs]} phx-change="change" class="p-4">
          <Components.Attribute.list
            attrs={@component[:attrs]}
            custom_params={@component[:custom_params]}
          />
        </form>
      </:attributes>
    </Components.Layout.show>
    """
  end
end
