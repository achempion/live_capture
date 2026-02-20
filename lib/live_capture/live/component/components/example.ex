defmodule LiveCapture.Component.Components.Example do
  use Phoenix.Component
  use LiveCapture.LiveCaptureDemo

  capture_all()

  def simple(assigns) do
    ~H"""
    <p>Hello, World!</p>
    """
  end

  attr :title, :string, default: "World"

  def with_default(assigns) do
    ~H"""
    <p>Hello, {@title}</p>
    """
  end

  attr :title, :string, examples: ["World", "Galaxy"]

  def with_example(assigns) do
    ~H"""
    <p>Hello, {@title}</p>
    """
  end

  attr :title, :string, default: "World"

  capture attributes: %{title: "Galaxy"}

  def with_capture_attributes(assigns) do
    ~H"""
    <p>Hello, {@title}</p>
    """
  end

  capture attributes: %{title: "World"}

  def without_attrs(assigns) do
    ~H"""
    <p>Hello, {@title}</p>
    """
  end

  attr :title, :string

  capture variants: [main: %{title: "Main"}, secondary: %{title: "Secondary"}]

  def with_capture_variants(assigns) do
    ~H"""
    <p>Hello, {@title}</p>
    """
  end

  slot :header
  slot :inner_block, required: true

  slot :cities, required: true do
    attr :name, :string, required: true
  end

  capture attributes: %{
            inner_block: "This is inner slot content.",
            header: %{inner_block: "Cities"},
            cities: [
              %{inner_block: "France", name: "Paris"},
              %{inner_block: "Germany", name: "Berlin"}
            ]
          }

  def with_slots(assigns) do
    ~H"""
    <div>
      <h3>{render_slot(@header)}</h3>

      <div>
        {render_slot(@inner_block)}
      </div>

      <ul>
        <%= if Enum.empty?(@cities) do %>
          <li>No cities listed.</li>
        <% else %>
          <li :for={city <- @cities}>
            <strong><%= city.name %></strong>: {render_slot(city)}
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  attr :title, :string

  slot :simple_heex
  slot :local_aliases

  capture attributes: %{
            title: "From Attribute!",
            simple_heex: "1+2 = {1+2}",
            local_aliases: """
            <.simple />
            <.with_default title={@title} />
            """
          }

  def with_heex_slots(assigns) do
    ~H"""
    <div>
      <h2>Simple</h2>
      {render_slot(@simple_heex)}

      <h2>Local aliases</h2>
      {render_slot(@local_aliases)}
    </div>
    """
  end

  slot :column do
    attr :label, :string, required: true
  end

  attr :rows, :list, default: []

  capture attributes: %{
            rows: [1, 2, 3],
            column: [
              %{inner_block: "row {row_number}", label: "Row number", let: :row_number},
              %{inner_block: "column", label: "Column"},
            ]
          }

  def table(assigns) do
    ~H"""
    <table>
      <tr>
        <th :for={col <- @column}>{col.label}</th>
      </tr>
      <tr :for={row <- @rows}>
        <td :for={col <- @column}>{render_slot(col, row)}</td>
      </tr>
    </table>
    """
  end
end
