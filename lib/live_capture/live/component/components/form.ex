defmodule LiveCapture.Component.Components.Form do
  use Phoenix.Component
  use LiveCapture.Component

  import Phoenix.HTML.Form

  attr :field, Phoenix.HTML.FormField,
    required: true,
    examples: [to_form(%{"test" => 2})[:test]]

  attr :options, :list, required: true, examples: [["Variant 1", 2, 3]]
  attr :class, :string, default: ""

  capture()

  def options(assigns) do
    ~H"""
    <div class="inline-flex rounded border overflow-hidden">
      <div :for={option <- @options}>
        <input
          type="radio"
          name={@field.name}
          id={input_id(@field.form, @field.field, option)}
          value={option}
          checked={@field.value == option}
          class="hidden peer"
        />
        <label
          for={input_id(@field.form, @field.field, option)}
          class="cursor-pointer px-4 py-2 peer-checked:bg-blue-200 peer-checked:hover:bg-blue-200 hover:bg-blue-100 peer-checked:hover:bg-blue-100"
        >
          <%= option %>
        </label>
      </div>
    </div>
    """
  end
end
