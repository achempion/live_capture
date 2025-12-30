defmodule LiveCapture.Component.ShowLive do
  use LiveCapture.Web, :live_view
  alias LiveCapture.Component.Components

  @config Application.get_env(:live_capture, LiveCapture, [])
  @breakpoints Keyword.get(@config, :breakpoints, [])

  def mount(_, _, socket) do
    modules = LiveCapture.Component.list()

    {:ok,
     assign(
       socket,
       modules: modules,
       component: nil,
       breakpoint_options:  Enum.map(@breakpoints, &to_string(elem(&1, 0))),
       frame_configuration: %{"breakpoint" => nil}
     )}
  end

  def handle_params(%{"module" => module, "function" => function}, _, socket) do
    module = Enum.find(socket.assigns.modules, &(to_string(&1) == module))

    if module do
      function =
        module.__captures__ |> Map.keys() |> Enum.find(&(to_string(&1) == function))

      phoenix_component = module.__components__[function] || %{}

      {:noreply,
       assign(socket,
         component: %{module: module, function: function, attrs: phoenix_component[:attrs]}
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

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

  defp iframe_style(frame_configuration) do
    breakpoint = frame_configuration["breakpoint"]
    breakpoint_value = breakpoint && @breakpoints[String.to_existing_atom(breakpoint)]

    breakpoint_value && "width: #{breakpoint_value}"
  end

  def render(assigns) do
    ~H"""
    <Components.Layout.show
      component={@component}
    >
      <:sidebar>
        <Components.Sidebar.show modules={@modules} component={@component} />
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
        <iframe
          :if={@component[:function]}
          class="h-full w-full bg-white absolute"
          src={"/raw/components/#{@component[:module]}/#{@component[:function]}?#{Plug.Conn.Query.encode(%{custom_params: @component[:custom_params]})}"}
          style={iframe_style(@frame_configuration)}
        >
        </iframe>
      </:render>

      <:docs>
        <.docs component={@component} />
      </:docs>
    </Components.Layout.show>
    """
  end

  defp docs(%{component: nil} = assigns) do
    ~H"""
    """
  end

  defp docs(assigns) do
    ~H"""
    <code class="whitespace-pre" phx-no-format>
      alias <%= @component[:module] %>

      &lt;<%= @component[:module] %>.<%= @component[:function] %> <.attrs list={@component[:attrs]} /> /&gt;
    </code>
    """
  end

  defp attrs(assigns) do
    signature =
      (assigns.list || [])
      |> Enum.map(fn attr ->
        case attr do
          %{name: name, opts: [examples: [example | _]]} ->
            [
              name,
              example
              |> inspect()
              |> Code.format_string!()
              |> Enum.join("")
              |> String.split("\n")
              |> Enum.join("\n")
            ]
            |> Enum.join("=")

          _ ->
            ""
        end
      end)
      |> Enum.join("\n")

    assigns = assign(assigns, :signature, signature)

    ~H"""
    <div class="ml-8"><%= @signature %></div>
    """
  end
end
