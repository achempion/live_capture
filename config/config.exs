import Config

if config_env() == :dev do
  config :esbuild,
    version: "0.17.11",
    capture_ui: [
      args: ~w(js/app.js --bundle --minify --target=es2020 --outdir=../dist/js ),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]
end
