defmodule LiveCapture.Component.Components.Attribute do
  use Phoenix.Component
  use LiveCapture.LiveCaptureDemo

  attr :attrs, :list,
    examples: [
      [
        %{name: :string, type: :string, opts: [examples: ["Your name"]]},
        %{name: :atom, type: :atom, opts: [examples: [:atom]]},
        %{name: :boolean, type: :boolean, opts: [examples: [:atom]]},
        %{name: :integer, type: :integer, opts: [examples: [42]]},
        %{name: :float, type: :float, opts: [examples: [42.43]]}
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
  attr :custom_param, :any, default: nil

  capture()

  def show(%{attr: %{type: :string}} = assigns) do
    assigns = set_value(assigns)

    ~H"""
    <.attr_row name={@attr.name} type={@attr.type}>
      <input class="border py-1 px-2 rounded" name={@attr.name} value={@value} />
    </.attr_row>
    """
  end

  def show(%{attr: %{type: :atom}} = assigns) do
    assigns = set_value(assigns)

    ~H"""
    <.attr_row name={@attr.name} type={@attr.type}>
      <input class="border py-1 px-2 rounded" name={@attr.name} value={@value} />
    </.attr_row>
    """
  end

  def show(%{attr: %{type: :boolean}} = assigns) do
    assigns = set_value(assigns)

    ~H"""
    <.attr_row name={@attr.name} type={@attr.type}>
      <input type="radio" id="yes" name={@attr.name} value="true" class="mr-2" />
      <label for="yes">true</label>
      <input type="radio" id="no" name={@attr.name} value="false" class="ml-4 mr-2" />
      <label for="no">false</label>
      <input type="radio" id="nil" name={@attr.name} value="false" class="ml-4 mr-2" />
      <label for="nil">nil</label>
    </.attr_row>
    """
  end

  def show(%{attr: %{type: :integer}} = assigns) do
    assigns = set_value(assigns)

    ~H"""
    <.attr_row name={@attr.name} type={@attr.type}>
      <input class="border py-1 px-2 rounded" name={@attr.name} value={@value} />
    </.attr_row>
    """
  end

  def show(%{attr: %{type: :float}} = assigns) do
    assigns = set_value(assigns)

    ~H"""
    <.attr_row name={@attr.name} type={@attr.type}>
      <input class="border py-1 px-2 rounded" name={@attr.name} value={@value} />
    </.attr_row>
    """
  end

  def show(%{attr: %{type: :list}} = assigns) do
    ~H"""
    list
    """
  end

  def show(assigns) do
    ~H"""
    Unsupported type: `{inspect(@attr[:type])}`
    """
  end

  defp attr_row(assigns) do
    ~H"""
    <div class="flex gap-4 items-center">
      <div>{@name}</div>
      <div class="border bg-gray-200 px-3 py-1 rounded-xl">{@type}</div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp set_value(assigns) do
    examples = Keyword.get(assigns.attr[:opts] || [], :examples, [])
    default_value = List.first(examples)
    value = assigns.custom_param || default_value

    assign(assigns, value: value)
  end
end
