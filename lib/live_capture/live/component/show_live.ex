defmodule LiveCapture.Component.ShowLive do
  use LiveCapture.Web, :live_view
  alias LiveCapture.Component.Components

  @config Application.get_env(:live_capture, LiveCapture, %{})
  @breakpoints Keyword.get(@config, :breakpoints, %{})

  def mount(_, _, socket) do
    modules =
      LiveCapture.Component.list()
      |> Enum.group_by(fn module ->
        to_string(module)
        |> String.split(".")
        |> List.pop_at(0)
        |> elem(1)
        |> List.pop_at(-1)
        |> elem(1)
        |> Enum.join(".")
      end)

    {:ok,
     assign(
       socket,
       modules: modules,
       component: nil,
       breakpoint_options: Map.keys(@breakpoints) |> Enum.map(&to_string(&1)),
       frame_configuration: %{"breakpoint" => nil}
     )}
  end

  def handle_params(%{"module" => module, "function" => function}, _, socket) do
    module =
      Enum.find(
        socket.assigns.modules |> Map.values() |> List.flatten(),
        &(to_string(&1) == module)
      )

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
    # params[:]

    {:noreply, assign(socket, frame_configuration: params["frame_configuration"])}
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
        <div class="text-xl text-center my-4">LiveCapture</div>
        <div :for={{group, list} <- @modules} class="mx-4 mb-4">
          <div class="font-semibold text-slate-900 mb-2"><%= group %></div>
          <div :for={module <- list} class="ml-4 mb-6">
            <div class="font-semibold text-slate-900 mb-2">
              <%= to_string(module) |> String.split(".") |> List.last() %>
            </div>
            <ul class="space-y-6 lg:space-y-2 border-l border-slate-300">
              <li>
                <.link
                  :for={{capture, _} <- module.__captures__}
                  navigate={"/components/#{module}/#{capture}"}
                  class={[
                    "-ml-px block pl-4 border-l cursor-pointer mb-b1052",
                    (module == @component[:module] && capture == @component[:function] &&
                       "border-slate-700 text-slate-900") ||
                      "hover:text-slate-900 hover:border-slate-700 border-slate-300 text-slate-700"
                  ]}
                >
                  <%= capture %>
                </.link>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div class="flex-1 flex flex-col shadow-md">
        <div class="border-b py-2 px-4 flex">
          <div class="ml-auto flex flex-col items-center">
            <div class="text-xs">Breakpoints</div>
            <.form
              :let={f}
              for={to_form(@frame_configuration)}
              as={:frame_configuration}
              phx-change="frame_configuration:change"
            >
              <Components.Form.options field={f[:breakpoint]} options={@breakpoint_options} />
            </.form>
          </div>
        </div>
        <div class="flex-1 bg-slate-100 relative overflow-scroll">
          <iframe
            :if={@component[:function]}
            class="h-full w-full bg-white absolute"
            src={"/raw/components/#{@component[:module]}/#{@component[:function]}?#{Plug.Conn.Query.encode(%{custom_params: @component[:custom_params]})}"}
            style={iframe_style(@frame_configuration)}
          >
          </iframe>
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
end
