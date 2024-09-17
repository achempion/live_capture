defmodule CaptureUI.Router do
  defmacro live_capture(path) do
    quote bind_quoted: binding() do
      import Phoenix.Router
      import Phoenix.LiveView.Router, only: [live: 2, live_session: 2]

      pipeline :capture_ui_browser do
        plug(Plug.Static,
          at: "/",
          from: :capture_ui,
          only: ~w(css js)
        )

        plug :put_root_layout, html: {CaptureUI.Layouts, :root}
      end

      scope path do
        pipe_through :capture_ui_browser

        live_session :capture_ui do
          live("/", CaptureUI.Main.ShowLive)
        end

        get "/*not_found", CaptureUI.PageController, :not_found
      end
    end
  end
end
