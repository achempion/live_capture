defmodule LiveCapture.Plugs.Assets do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _), do: put_private(conn, :plug_skip_csrf_protection, true)
end
