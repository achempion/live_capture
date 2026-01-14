#######################################
# Development Server for LiveCapture
#
# $ iex -S mix dev
#######################################

Logger.configure(level: :debug)

# Configures the endpoint
Application.put_env(:live_capture, DemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "G1NXGZJiMBnjjFR+cXdeavjK5poXpRrOB6OBi4wHo53g/utCds5P6X+qkcpF/otD",
  live_view: [signing_salt: "Z8MZuOET"],
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  check_origin: false,
  pubsub_server: Demo.PubSub,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:live_capture, ~w(--watch)]},
    tailwind: {Tailwind, :install_and_run, [:live_capture, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/*/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/live_capture/(live|views)/.*(ex)$"
    ]
  ]
)

defmodule DemoWeb.Router do
  use Phoenix.Router
  import LiveCapture.Router

  pipeline :browser do
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through(:browser)

    live_capture "/", LiveCapture.LiveCaptureDemo
  end
end

defmodule DemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :live_capture

  @session_options [
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "aI3XMwdQvod8U3MYgpKDxUO0TIbp",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)

  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader)

  plug(Plug.Session, @session_options)

  plug(Plug.RequestId)
  plug(DemoWeb.Router)
end

Application.put_env(:phoenix, :serve_endpoints, true)

Task.async(fn ->
  children =
    [
      {Phoenix.PubSub, [name: Demo.PubSub, adapter: Phoenix.PubSub.PG2]},
      DemoWeb.Endpoint
    ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  Process.sleep(:infinity)
end)
