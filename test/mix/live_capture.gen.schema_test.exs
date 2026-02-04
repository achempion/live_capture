defmodule Mix.Tasks.LiveCapture.Gen.SchemaTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  alias Mix.Tasks.LiveCapture.Gen.Schema

  describe "run/1" do
    test "prints schema JSON to STDOUT with url prefix" do
      stdout =
        capture_io(fn ->
          Schema.run([
            "--module",
            "LiveCapture.LiveCaptureDemo",
            "--url-prefix",
            "/dev/live_capture"
          ])
        end)

      [schema] = Jason.decode!(stdout)

      assert %{
               "schema" => "LiveCapture.LiveCaptureDemo",
               "breakpoints" => [
                 %{"name" => "s", "width" => "480px"},
                 %{"name" => "m", "width" => "768px"},
                 %{"name" => "l", "width" => "1279px"},
                 %{"name" => "xl", "width" => "1600px"}
               ],
               "captures" => captures
             } = schema

      assert captures |> Enum.filter(&(&1["function"] == "simple")) == [
               %{
                 "function" => "simple",
                 "module" => "LiveCapture.Component.Components.Example",
                 "variant" => nil,
                 "url" =>
                   "/dev/live_capture/raw/components/Elixir.LiveCapture.Component.Components.Example/simple"
               }
             ]

      assert captures |> Enum.filter(&(&1["function"] == "with_capture_variants")) == [
               %{
                 "function" => "with_capture_variants",
                 "module" => "LiveCapture.Component.Components.Example",
                 "url" =>
                   "/dev/live_capture/raw/components/Elixir.LiveCapture.Component.Components.Example/with_capture_variants/main",
                 "variant" => "main"
               },
               %{
                 "function" => "with_capture_variants",
                 "module" => "LiveCapture.Component.Components.Example",
                 "url" =>
                   "/dev/live_capture/raw/components/Elixir.LiveCapture.Component.Components.Example/with_capture_variants/secondary",
                 "variant" => "secondary"
               }
             ]
    end

    test "writes schema JSON to output path without url prefix" do
      output_path =
        Path.join(System.tmp_dir!(), "captures.#{System.unique_integer([:positive])}.json")

      on_exit(fn ->
        File.rm!(output_path)
      end)

      Schema.run([
        "--module",
        "LiveCapture.LiveCaptureDemo",
        output_path
      ])

      [schema] = output_path |> File.read!() |> Jason.decode!()

      assert schema |> Map.keys() |> Enum.sort() == ["breakpoints", "captures", "schema"]

      assert Enum.filter(schema["captures"], &(&1["function"] == "simple")) == [
               %{
                 "function" => "simple",
                 "module" => "LiveCapture.Component.Components.Example",
                 "variant" => nil,
                 "url" => "/raw/components/Elixir.LiveCapture.Component.Components.Example/simple"
               }
             ]
    end
  end
end
