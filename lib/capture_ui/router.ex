defmodule CaptureUI.Router do
  defmacro live_capture(path) do
    quote bind_quoted: binding() do
      import Phoenix.LiveView.Router, only: [live: 2, live_session: 2]

      scope path do
        live_session :capture_ui do
          live("/", CaptureUI.Main.ShowLive)
        end
      end
    end
  end
end
