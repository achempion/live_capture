defmodule LiveCapture.Component.Components.Attribute do
  use Phoenix.Component
  use LiveCapture.Component

  attr :attrs, :list,
    examples: [
      [
        %{name: :name1, type: :string, opts: [examples: ["Your name"]]},
        %{name: :name2, type: :string, opts: [examples: ["Your name"]]}
      ]
    ]

  attr :custom_params, :map, examples: [%{}]

  capture()

  def list(assigns) do
    ~H"""
    <div :for={attr <- @attrs} class="m-4">
      <.show attr={attr} custom_param={@custom_params[to_string(attr.name)]} />
    </div>
    """
  end

  attr :attr, :map, examples: [%{name: :name, type: :string}]

  capture()

  def show(%{attr: %{type: :string}} = assigns) do
    value = Keyword.get(assigns.attr[:opts] || [], :examples, []) |> List.first()

    assigns = assign(assigns, value: value)

    ~H"""
    <div class="flex gap-4 items-center">
      <div><%= @attr.name %></div>
      <div class="border bg-gray-200 px-3 py-1 rounded-xl"><%= @attr.type %></div>
      <input class="border py-1 px-2 rounded" name={@attr.name} value={@value} />
    </div>
    """
  end

  def show(%{attr: %{type: :list}} = assigns) do
    ~H"""
    list
    """
  end

  def show(assigns) do
    ~H"""
    Unsupported type: `<%= inspect(@attr[:type]) %>`
    """
  end
end
