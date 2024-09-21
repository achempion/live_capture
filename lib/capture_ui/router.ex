defmodule CaptureUI.Router do
  defmodule __MODULE__.Assets do
    import Plug.Conn
    def init(opts), do: opts
    def call(conn, _), do: put_private(conn, :plug_skip_csrf_protection, true)
  end

  defmacro live_capture(path) do
    quote bind_quoted: binding() do
      import Phoenix.Router
      import Phoenix.LiveView.Router, only: [live: 2, live_session: 2]

      pipeline :capture_ui_static do
        plug CaptureUI.Router.Assets

        plug Plug.Static,
          at: "/",
          from: :capture_ui,
          only: ~w(css js)
      end

      pipeline :capture_ui_browser do
        plug :put_root_layout, html: {CaptureUI.Layouts, :root}
      end

      scope path do
        pipe_through :capture_ui_browser

        live_session :capture_ui do
          live("/", CaptureUI.Main.ShowLive)
          live("/components/:module/:function", CaptureUI.Component.ShowLive)
        end

        pipe_through :capture_ui_static

        get "/*not_found", CaptureUI.PageController, :not_found
      end
    end
  end
end
