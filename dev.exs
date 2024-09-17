#######################################
# Development Server for CaptureUI
#
# $ iex -S mix dev
#######################################

Logger.configure(level: :debug)

# Configures the endpoint
Application.put_env(:capture_ui, DemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "G1NXGZJiMBnjjFR+cXdeavjK5poXpRrOB6OBi4wHo53g/utCds5P6X+qkcpF/otD",
  live_view: [signing_salt: "Z8MZuOET"],
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  check_origin: false,
  pubsub_server: Demo.PubSub,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:capture_ui, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"dist/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/capture_ui/live_capture/(live|views)/.*(ex)$",
      ~r"lib/capture_ui/live_capture/templates/.*(ex)$"
    ]
  ]
)

defmodule DemoWeb.Router do
  use Phoenix.Router
  import CaptureUI.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_csp)
  end

  scope "/" do
    pipe_through(:browser)

    live_capture("/")
  end

  def put_csp(conn, _opts) do
    [img_nonce, style_nonce, script_nonce] =
      for _i <- 1..3, do: 16 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

    conn
    |> assign(:img_csp_nonce, img_nonce)
    |> assign(:style_csp_nonce, style_nonce)
    |> assign(:script_csp_nonce, script_nonce)
    |> put_resp_header(
      "content-security-policy",
      "default-src; script-src 'nonce-#{script_nonce}'; style-src-elem 'nonce-#{style_nonce}'; " <>
        "img-src 'nonce-#{img_nonce}' data: ; font-src data: ; connect-src 'self'; frame-src 'self' ;"
    )
  end
end

defmodule DemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :capture_ui

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
|> Task.await(:infinity)
