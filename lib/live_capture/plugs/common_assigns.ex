defmodule LiveCapture.Plugs.CommonAssigns do
  import Phoenix.Component

  def on_mount({path, modules}, _params, _session, socket) do
    {:cont,
     assign(
       socket,
       component_loaders: modules,
       live_capture_path: LiveCapture.Plugs.AssetsConfig.assets_scope(path)
     )}
  end
end
