defmodule CaptureUI.Component.Components.Attribute do
  use Phoenix.Component
  use CaptureUI.Component

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

  capture()

  def show(%{attr: %{type: :string}} = assigns) do
    example = Keyword.get(assigns.attr[:opts] || [], :examples, []) |> List.first()

    assigns = assign(assigns, example: example)

    ~H"""
    <div class="flex gap-4 items-center">
      <div><%= @attr.name %></div>
      <div class="border bg-gray-200 px-3 py-1 rounded-xl"><%= @attr.type %></div>
      <input class="border py-1 px-2 rounded" value={example} />
    </div>
    """
  end

  def show(%{attr: %{type: :list}} = assigns) do
    ~H"""
    list
    """
  end
end
