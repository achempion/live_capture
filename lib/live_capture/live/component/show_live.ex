defmodule LiveCapture.Component.ShowLive do
  use LiveCapture.Web, :live_view
  alias LiveCapture.Component.Components

  @config Application.get_env(:live_capture, LiveCapture, [])
  @breakpoints Keyword.get(@config, :breakpoints, %{})

  def mount(_, _, socket) do
    modules = LiveCapture.Component.list()

    {:ok,
     assign(
       socket,
       modules: modules,
       component: nil,
       breakpoint_options: Map.keys(@breakpoints) |> Enum.map(&to_string(&1)),
       docs_options: ["Bottom", "Right"],
       frame_configuration: %{"breakpoint" => nil, "docs" => "Bottom"}
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
    <div class="flex min-h-svh">
      <div class="w-96 bg-slate-100">
        <.sidebar modules={@modules} component={@component} />
      </div>
      <div class="flex-1 flex flex-col shadow-md">
        <div class="border-b py-2 px-4 flex">
          <.form
            :let={f}
            for={to_form(@frame_configuration)}
            as={:frame_configuration}
            phx-change="frame_configuration:change"
            class="ml-auto flex gap-4"
          >
            <div class="flex flex-col items-center">
              <div class="text-xs">Docs</div>
              <Components.Form.options field={f[:docs]} options={@docs_options} />
            </div>

            <div class="flex flex-col items-center">
              <div class="text-xs">Breakpoints</div>
              <Components.Form.options field={f[:breakpoint]} options={@breakpoint_options} />
            </div>
          </.form>
        </div>

        <div class={["flex flex-1", @frame_configuration["docs"] == "Bottom" && "flex-col"]}>
          <div class="flex flex-1 bg-slate-100 relative overflow-scroll">
            <iframe
              :if={@component[:function]}
              class="h-full w-full bg-white absolute"
              src={"/raw/components/#{@component[:module]}/#{@component[:function]}?#{Plug.Conn.Query.encode(%{custom_params: @component[:custom_params]})}"}
              style={iframe_style(@frame_configuration)}
            >
            </iframe>
          </div>
          <div class={[
            @frame_configuration["docs"] == "Right" && "border-l w-[40%]",
            @frame_configuration["docs"] == "Bottom" && "border-t h-[40%]",
            !@frame_configuration["docs"] && "hidden"
          ]}>
            <.docs component={@component} />
          </div>
        </div>
        <div :if={@component} class="border-t">
          <form phx-change="change">
            <Components.Attribute.list
              :if={@component[:attrs]}
              attrs={@component[:attrs]}
              custom_params={@component[:custom_params]}
            />
          </form>
        </div>
      </div>
    </div>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <div>
      <div class="text-xl text-center my-4">LiveCapture</div>
      <div class="mx-4 space-y-6">
        <div :for={module <- @modules} class="space-y-2">
          <div class="font-semibold text-slate-900">
            <%= module |> Module.split() |> Enum.join(".") %>
          </div>
          <ul class="border-l border-slate-300 space-y-2">
            <li :for={{capture, _} <- module.__captures__}>
              <.link
                navigate={"/components/#{module}/#{capture}"}
                class={[
                  "-ml-px block pl-4 border-l cursor-pointer",
                  (module == @component[:module] && capture == @component[:function] &&
                     "border-slate-700 text-slate-900") ||
                    "hover:text-slate-900 hover:border-slate-700 border-slate-300 text-slate-700"
                ]}
              >
                <%= capture %>/<%= attr_count(module, capture) %>
              </.link>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp attr_count(module, capture) do
    module.__components__
    |> Map.get(capture, %{})
    |> Map.get(:attrs, [])
    |> length()
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
