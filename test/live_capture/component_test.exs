defmodule LiveCapture.ComponentTest do
  use ExUnit.Case, async: true

  alias LiveCapture.Component.Components.Example

  describe "attributes/3" do
    test "wihtout arguments" do
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

    test "with caputure attributes" do
      attributes = %{title: "Galaxy"}

      assert LiveCapture.Component.attributes(Example, :with_capture_attributes) == attributes
    end

    test "with caputure attributes and without attrs" do
      attributes = %{title: "World"}

      assert LiveCapture.Component.attributes(Example, :without_attrs) == attributes
    end

    test "with caputure default variant" do
      attributes = %{title: "Main"}

      assert LiveCapture.Component.attributes(Example, :with_capture_variants) ==
               attributes
    end

    test "with caputure variant" do
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
end
