defmodule Mix.Tasks.LiveCapture.Gen.Schema do
  use Mix.Task

  Code.ensure_compiled!(Jason)

  @shortdoc "Generates a JSON schema for capture modules"

  @moduledoc """
  Generates a JSON schema for capture modules

  This is useful for automated visual regression testing with [Playwright](https://playwright.dev/docs/test-snapshots).

  ## Usage

      mix live_capture.gen.schema --module MyAppWeb.LiveCapture --url-prefix /storybook path/to/captures.json

  Tip: pass multiple modules by duplicating `--module` switches

  `--url-prefix` should match the scope of mounted live_capture routes

  Skip path to print schema to stdout.

  ## Output Format

  **captures.json**

  ```json
  [
    {
      "schema": "MyAppWeb.LiveCapture",
      "breakpoints": [
        {"name": "s", "width": "480px"},
        {"name": "m", "width": "768px"}
      ],
      "captures": [
        {"module": "MyAppWeb.Example", "function": "simple", "variant": null, "url": "/storybook/raw/components/Example/button"},
        {"module": "MyAppWeb.Example", "function": "with_capture_variants", "variant": "main", "url": "/storybook/raw/components/Example/button/main"},
        {"module": "MyAppWeb.Example", "function": "with_capture_variants", "variant": "secondary", "url": "/storybook/raw/components/Example/button/secondary"}
      ]
    }
  ]
  ```
  """

  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args,
        strict: [module: :keep, url_prefix: :string],
        aliases: [m: :module, u: :url_prefix]
      )

    output_path = List.first(positional)

    url_prefix = Keyword.get(opts, :url_prefix, "/")

    component_loaders =
      opts
      |> Keyword.get_values(:module)
      |> Enum.map(&String.to_existing_atom("Elixir.#{&1}"))

    component_loaders
    |> Enum.map(&to_schema(&1, url_prefix))
    |> Jason.encode!(pretty: true)
    |> write!(output_path)
  end

  defp to_schema(component_loader, url_prefix) do
    breakpoints =
      component_loader.breakpoints()
      |> Enum.map(fn {name, width} ->
        %{name: name, width: width}
      end)

    %{
      schema: to_display(component_loader),
      breakpoints: breakpoints,
      captures: captures([component_loader], url_prefix)
    }
  end

  defp captures(component_loaders, url_prefix) do
    component_loaders
    |> LiveCapture.Component.list()
    |> Enum.flat_map(&variants(&1, url_prefix))
  end

  defp variants(module, url_prefix) do
    Enum.flat_map(module.__live_capture__()[:captures], fn {function, config} ->
      config
      |> Map.get(:variants, [{nil, %{}}])
      |> Enum.map(fn {variant, _} ->
        prefix = String.trim_trailing(url_prefix, "/")
        suffix = [module, function, variant] |> Enum.reject(&is_nil/1) |> Enum.join("/")

        %{
          module: to_display(module),
          function: function,
          variant: variant,
          url: "#{prefix}/raw/components/#{suffix}"
        }
      end)
    end)
  end

  defp write!(json, nil), do: Mix.shell().info(json)

  defp write!(json, path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(path, json)
  end

  defp to_display(module) when is_atom(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
