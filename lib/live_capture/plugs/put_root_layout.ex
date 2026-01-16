defmodule LiveCapture.Plugs.PutRootLayout do
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
end
