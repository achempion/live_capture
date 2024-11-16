defmodule LiveCapture.Component.Components.Attribute do
  use Phoenix.Component
  use LiveCapture.Component

  attr :attrs, :list,
    examples: [
      [
        %{name: :name, type: :string, opts: [examples: ["Your name"]]},
        %{name: :name, type: :string, opts: [examples: ["Your name"]]}
      ]
    ]

  capture()

  def list(assigns) do
    ~H"""
    <div :for={attr <- @attrs} class="m-4">
      <.show attr={attr} />
    </div>
    """
  end

  attr :attr, :map, examples: [%{name: :name, type: :string}]

  capture()

  def show(%{attr: %{type: :string}} = assigns) do
    example = Keyword.get(assigns.attr[:opts] || [], :examples, []) |> List.first()

    assigns =
      if is_nil(example) do
        assigns
      else
        assign(assigns, example: example)
      end

    ~H"""
    <div class="flex gap-4 items-center">
      <div><%= @attr.name %></div>
      <div class="border bg-gray-200 px-3 py-1 rounded-xl"><%= @attr.type %></div>
      <input class="border py-1 px-2 rounded" value={assigns[:example]} />
    </div>
    """
  end

  def show(%{attr: %{type: :list}} = assigns) do
    ~H"""
    list
    """
  end

  def show(%{attr: %{type: type}} = assigns) do
    ~H"""
    Unsupported type: `<%= inspect(type) %>`
    """
  end
end
