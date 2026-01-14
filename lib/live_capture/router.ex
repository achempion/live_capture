defmodule LiveCapture.Router do
  defmodule __MODULE__.Assets do
    import Plug.Conn
    def init(opts), do: opts
    def call(conn, _), do: put_private(conn, :plug_skip_csrf_protection, true)
  end

  defmodule __MODULE__.PutAssetsScope do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, opts) do
      assign(conn, :live_capture_path, opts |> Keyword.fetch!(:scope) |> assets_scope())
    end

    def assets_scope("/"), do: ""
    def assets_scope(val), do: val
  end

  defmodule __MODULE__.PutRootLayout do
    def init(opts), do: opts

    def call(conn, opts) do
      if Map.has_key?(conn.params, "module") do
        module =
          Keyword.fetch!(opts, :component_loaders)
          |> LiveCapture.Component.list()
          |> Enum.find(&(to_string(&1) == conn.params["module"]))

        Phoenix.Controller.put_root_layout(conn, module.__live_capture__()[:loader].root_layout())
      else
        conn
      end
    end

    def assets_scope("/"), do: ""
    def assets_scope(val), do: val
  end

  defmodule __MODULE__.CommonAssigns do
    import Phoenix.Component

    def on_mount({path, modules}, _params, _session, socket) do
      {:cont,
       assign(
         socket,
         component_loaders: modules,
         live_capture_path: LiveCapture.Router.PutAssetsScope.assets_scope(path)
       )}
    end
  end

  defmacro live_capture(path, component_loaders \\ [], opts \\ []) do
    quote bind_quoted: [path: path, component_loaders: component_loaders, opts: opts] do
      import Phoenix.Router
      import Phoenix.LiveView.Router, only: [live: 2, live_session: 3]

      component_loaders = List.wrap(component_loaders)

      pipeline :live_capture_static do
        plug LiveCapture.Router.Assets
        plug LiveCapture.Router.PutAssetsScope, scope: path

        get "/liveview/css-:md5", LiveCapture.LiveViewAssets, :css
        get "/liveview/js-:md5", LiveCapture.LiveViewAssets, :js

        plug Plug.Static,
          at: path,
          from: :live_capture,
          only: ~w(css js)
      end

      pipeline :live_capture_browser do
        plug LiveCapture.Router.PutAssetsScope, scope: path
      end

      pipeline :raw_browser do
        plug LiveCapture.Router.PutRootLayout, component_loaders: component_loaders
      end

      scope path do
        pipe_through :live_capture_browser

        live_session :live_capture,
          on_mount: {LiveCapture.Router.CommonAssigns, {path, component_loaders}},
          root_layout: {LiveCapture.Layouts, :root} do
          live("/", LiveCapture.Component.ShowLive)
          live("/components/:module/:function", LiveCapture.Component.ShowLive)
          live("/components/:module/:function/:variant", LiveCapture.Component.ShowLive)
        end

        pipe_through :raw_browser

        live_session :live_capture_raw,
          on_mount: {LiveCapture.Router.CommonAssigns, {path, component_loaders}} do
          live("/raw/components/:module/:function", LiveCapture.RawComponent.ShowLive)
          live("/raw/components/:module/:function/:variant", LiveCapture.RawComponent.ShowLive)
        end

        pipe_through :live_capture_static

        get "/*not_found", LiveCapture.PageController, :not_found
      end
    end
  end
end
