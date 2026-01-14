defmodule LiveCapture.ComponentTest do
  use ExUnit.Case, async: true

  alias LiveCapture.Component.Components.Example

  test "loader configuration" do
    assert LiveCapture.LiveCaptureDemo.breakpoints() == [
             s: "480px",
             m: "768px",
             l: "1279px",
             xl: "1600px"
           ]

    assert LiveCapture.LiveCaptureDemo.root_layout() == {LiveCapture.Layouts, :root}
  end

  describe "__live_capture__/0" do
    test "has loader module" do
      assert Example.__live_capture__().loader == LiveCapture.LiveCaptureDemo
    end
  end

  describe "attributes/3" do
    test "without arguments" do
      attributes = %{}

      assert LiveCapture.Component.attributes(Example, :simple) == attributes
    end

    test "with default argument" do
      attributes = %{title: "World"}

      assert LiveCapture.Component.attributes(Example, :with_default) == attributes
    end

    test "with example argument" do
      attributes = %{title: "World"}

      assert LiveCapture.Component.attributes(Example, :with_example) == attributes
    end

    test "with capture attributes" do
      attributes = %{title: "Galaxy"}

      assert LiveCapture.Component.attributes(Example, :with_capture_attributes) == attributes
    end

    test "with capture attributes and without attrs" do
      attributes = %{title: "World"}

      assert LiveCapture.Component.attributes(Example, :without_attrs) == attributes
    end

    test "with capture default variant" do
      attributes = %{title: "Main"}

      assert LiveCapture.Component.attributes(Example, :with_capture_variants) ==
               attributes
    end

    test "with capture variant" do
      attributes = %{title: "Secondary"}

      assert LiveCapture.Component.attributes(Example, :with_capture_variants, :secondary) ==
               attributes
    end

    test "with slots" do
      attributes = %{
        inner_block: "This is inner slot content.",
        header: %{inner_block: "Cities"},
        cities: [
          %{inner_block: "France", name: "Paris"},
          %{inner_block: "Germany", name: "Berlin"}
        ]
      }

      assert LiveCapture.Component.attributes(Example, :with_slots) == attributes
    end
  end

  describe "render/3" do
    test "without arguments" do
      assert component_render(Example, :simple) =~ "Hello, World"
    end

    test "with default argument" do
      assert component_render(Example, :with_default) =~ "Hello, World"
    end

    test "with example argument" do
      assert component_render(Example, :with_example) =~ "Hello, World"
    end

    test "with capture attributes" do
      assert component_render(Example, :with_capture_attributes) =~ "Hello, Galaxy"
    end

    test "with capture attributes and without attrs" do
      assert component_render(Example, :without_attrs) =~ "Hello, World"
    end

    test "with capture default variant" do
      assert component_render(Example, :with_capture_variants) =~ "Hello, Main"
    end

    test "with capture variant" do
      assert component_render(Example, :with_capture_variants, :secondary) =~ "Hello, Secondary"
    end

    test "with slots" do
      rendered = component_render(Example, :with_slots)

      assert rendered =~ "Cities"
      assert rendered =~ "This is inner slot content."
      assert rendered =~ "Paris</strong>: France"
      assert rendered =~ "Berlin</strong>: Germany"
    end
  end

  defp component_render(module, function, variant \\ nil) do
    {:safe, list} =
      __ENV__
      |> LiveCapture.Component.render(module, function, variant)
      |> Phoenix.HTML.html_escape()

    Enum.join(list)
  end
end
