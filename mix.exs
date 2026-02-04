defmodule LiveCapture.MixProject do
  use Mix.Project

  @version "0.2.5"

  def project do
    [
      app: :live_capture,
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      listeners: [Phoenix.CodeReloader],
      deps: deps(),
      aliases: aliases(),
      docs: &docs/0,
      source_url: "https://github.com/achempion/live_capture",
      description: description(),
      package: package()
    ]
  end

  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: [:logger]]
  end

  defp description() do
    "Improve the UI quality of your product by capturing visual states of LiveView components."
  end

  defp package() do
    [
      maintainers: ["Boris Kuznetsov"],
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib priv .formatter.exs),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/achempion/live_capture"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"},
      {:jason, "~> 1.0"},

      # Dev
      {:plug_cowboy, "~> 2.0", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:esbuild, "~> 0.8", only: :dev},
      {:tailwind, "~> 0.2", only: :dev},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end

  defp aliases do
    [
      dev: "run --no-halt dev.exs",
      "assets.deploy": [
        "tailwind live_capture --minify",
        "esbuild live_capture --minify"
      ]
    ]
  end
end
