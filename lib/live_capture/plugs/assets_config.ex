defmodule LiveCapture.Plugs.AssetsConfig do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> put_private(:live_capture_path, opts |> Keyword.fetch!(:scope) |> assets_scope())
    |> put_private(:csp_nonce_assign_key, Keyword.fetch!(opts, :csp_nonce_assign_key))
  end

  def assets_scope("/"), do: ""
  def assets_scope(val), do: val
end
