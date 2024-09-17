defmodule CaptureUI.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :capture_ui,
      version: @version,
      elixir: "~> 1.4",
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
