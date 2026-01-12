defmodule LiveCapture.LiveViewAssets do
  import Plug.Conn

  phoenix_js_paths =
    for app <- [:phoenix, :phoenix_html, :phoenix_live_view] do
      path = Application.app_dir(app, ["priv", "static", "#{app}.js"])
      Module.put_attribute(__MODULE__, :external_resource, path)
      path
    end

  @js """
  #{for path <- phoenix_js_paths, do: path |> File.read!() |> String.replace("//# sourceMappingURL=", "// ")}
  """

  @hashes %{
    js: Base.encode16(:crypto.hash(:md5, @js), case: :lower)
  }

  def init(asset) when asset in [:js, :css], do: asset

  def call(conn, asset) do
    {contents, content_type} =
      case asset do
        :js -> {@js, "text/javascript"}
      end

    conn
    |> put_resp_header("content-type", content_type)
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> put_private(:plug_skip_csrf_protection, true)
    |> send_resp(200, contents)
    |> halt()
  end

  def current_hash(:js), do: @hashes.js
end
