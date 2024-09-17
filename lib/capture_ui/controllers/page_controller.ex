defmodule CaptureUI.PageController do
  use Phoenix.Controller

  def not_found(conn, _) do
    send_resp(conn, 405, "world")
  end
end
