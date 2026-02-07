defmodule LiveCapture.Component.Components.ExampleSecond do
  use Phoenix.Component
  use LiveCapture.LiveCaptureDemoSecond

  capture()

  def simple(assigns) do
    ~H"""
    <p>Hello, World!</p>
    """
  end
end
