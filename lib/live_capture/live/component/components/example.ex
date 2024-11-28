defmodule LiveCapture.Component.Components.Example do
  use Phoenix.Component
  use LiveCapture.Component

  capture()

  def hello_world(assigns) do
    ~H"""
    <p>Hello world!</p>
    """
  end

  attr :title, :string, examples: ["Earth"]
  capture()

  def complex(assigns) do
    ~H"""
    <p>Hello <%= @title %>!</p>
    """
  end
end
