defmodule LiveCapture.Component.Components.Example do
  use Phoenix.Component
  use LiveCapture.Component

  capture_all()

  def hello_world(assigns) do
    ~H"""
    <p>Hello world!</p>
    """
  end

  attr :title, :string

  capture(
    variants: [
      earth: %{attrs: %{title: "Earth"}},
      moon: %{attrs: %{title: "Moon"}}
    ]
  )

  def complex(assigns) do
    ~H"""
    <p>Hello <%= @title %>!</p>
    """
  end

  attr :title, :string, default: "Cities"

  slot :inner_block, required: true

  slot :cities, required: true do
    attr :name, :string, required: true
  end

  capture(
    variants: [
      main: %{
        slots: %{
          inner_block: "This is inner slot content.",
          cities: [
            %{name: "Paris", content: "France"},
            %{name: "Berlin", content: "Germany"}
          ]
        }
      }
    ]
  )

  def with_slot(assigns) do
    ~H"""
    <div>
      <h3><%= @title %></h3>

      <div>
        <%= render_slot(@inner_block) %>
      </div>

      <ul>
        <%= if Enum.empty?(@cities) do %>
          <li>No cities listed.</li>
        <% else %>
          <li :for={city <- @cities}>
            <strong><%= city.name %></strong>: <%= render_slot(city) %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
