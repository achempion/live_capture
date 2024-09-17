import Config

if config_env() == :dev do
  config :esbuild,
    version: "0.17.11",
    capture_ui: [
      args: ~w(js/app.js --bundle --minify --target=es2020 --outdir=../priv/static/js ),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]

  config :tailwind,
    version: "3.4.3",
    capture_ui: [
      args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/css/app.css
    ),
      cd: Path.expand("../assets", __DIR__)
    ]
end
