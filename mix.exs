defmodule CaptureUI.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :capture_ui,
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 0.19 or ~> 1.0"},

      # Dev
      {:plug_cowboy, "~> 2.0", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:jason, "~> 1.0", only: :dev},
      {:esbuild, "~> 0.8", only: :dev},
    ]
  end

  defp aliases do
    [
      dev: "run --no-halt dev.exs"
    ]
  end
end
