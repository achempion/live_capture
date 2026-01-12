defmodule LiveCapture.Router do
  defmodule __MODULE__.Assets do
    import Plug.Conn
    def init(opts), do: opts
    def call(conn, _), do: put_private(conn, :plug_skip_csrf_protection, true)
  end

  defmodule __MODULE__.AssignPath do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, opts) do
      path = (opts[:path] == "/" && "") || opts[:path]
      assign(conn, :live_capture_path, path)
    end

    def on_mount(path, _params, _session, socket) do
      {:cont, Phoenix.Component.assign(socket, :live_capture_path, (path == "/" && "") || path)}
    end
  end

  defmacro live_capture(path, opts \\ []) do
    quote bind_quoted: [path: path, opts: opts] do
      import Phoenix.Router
      import Phoenix.LiveView.Router, only: [live: 2, live_session: 3]

      default_root_layout = {LiveCapture.Layouts, :root}
      raw_root_layout = Keyword.get(opts, :root_layout, default_root_layout)

      pipeline :live_capture_static do
        plug LiveCapture.Router.Assets
        plug LiveCapture.Router.AssignPath, path: path

        get "/liveview/css-:md5", LiveCapture.LiveViewAssets, :css
        get "/liveview/js-:md5", LiveCapture.LiveViewAssets, :js

        plug Plug.Static,
          at: path,
          from: :live_capture,
          only: ~w(css js)
      end

      pipeline :live_capture_browser do
        plug LiveCapture.Router.AssignPath, path: path
      end

      scope path do
        pipe_through :live_capture_browser

        live_session :live_capture,
          on_mount: {LiveCapture.Router.AssignPath, path},
          root_layout: default_root_layout do
          live("/", LiveCapture.Component.ShowLive)
          live("/components/:module/:function", LiveCapture.Component.ShowLive)
          live("/components/:module/:function/:variant", LiveCapture.Component.ShowLive)
        end

        live_session :live_capture_raw,
          on_mount: {LiveCapture.Router.AssignPath, path},
          root_layout: raw_root_layout do
          live("/raw/components/:module/:function", LiveCapture.RawComponent.ShowLive)
          live("/raw/components/:module/:function/:variant", LiveCapture.RawComponent.ShowLive)
        end

        pipe_through :live_capture_static

        get "/*not_found", LiveCapture.PageController, :not_found
      end
    end
  end
end
