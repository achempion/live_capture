defmodule LiveCapture.Router do
  defmacro live_capture(path, component_loaders \\ [], opts \\ []) do
    quote bind_quoted: [path: path, component_loaders: component_loaders, opts: opts] do
      import Phoenix.Router
      import Phoenix.LiveView.Router, only: [live: 2, live_session: 3]
      alias LiveCapture.Plugs

      component_loaders = List.wrap(component_loaders)

      pipeline :live_capture_static do
        plug Plugs.Assets

        plug Plug.Static,
          at: path,
          from: :live_capture,
          only: ~w(css js)
      end

      pipeline :live_capture_browser do
        plug Plugs.AssetsConfig,
          scope: path,
          csp_nonce_assign_key: Keyword.get(opts, :csp_nonce_assign_key, %{})
      end

      pipeline :raw_browser do
        plug Plugs.PutRootLayout, component_loaders: component_loaders
        plug LiveCapture.Plugs.LoaderPlugs, component_loaders: component_loaders
      end

      scope path do
        pipe_through :live_capture_browser

        live_session :live_capture,
          on_mount: {Plugs.CommonAssigns, {path, component_loaders}},
          root_layout: {LiveCapture.Layouts, :root},
          session: {Plugs.AssetsConfig, :live_session, []} do
          live("/", LiveCapture.Component.ShowLive)
          live("/components/:module/:function", LiveCapture.Component.ShowLive)
          live("/components/:module/:function/:variant", LiveCapture.Component.ShowLive)
        end

        pipe_through :raw_browser

        live_session :live_capture_raw,
          on_mount: {Plugs.CommonAssigns, {path, component_loaders}},
          session: {Plugs.AssetsConfig, :live_session, []} do
          live("/raw/components/:module/:function", LiveCapture.RawComponent.ShowLive)
          live("/raw/components/:module/:function/:variant", LiveCapture.RawComponent.ShowLive)
        end

        pipe_through :live_capture_static
        get "/liveview/css-:md5", LiveCapture.LiveViewAssets, :css
        get "/liveview/js-:md5", LiveCapture.LiveViewAssets, :js

        get "/*not_found", LiveCapture.PageController, :not_found
      end
    end
  end
end
