defmodule LiveCapture.Component.Components.Form do
  use Phoenix.Component
  use LiveCapture.LiveCaptureDemo

  import Phoenix.HTML.Form

  attr :field, Phoenix.HTML.FormField,
    required: true,
    examples: [to_form(%{"test" => 2})[:test]]

  attr :options, :list, required: true, examples: [["Variant 1", 2, 3]]

  capture()

  def options(assigns) do
    ~H"""
    <div class="inline-flex items-stretch">
      <input
        class="hidden"
        type="radio"
        name={@field.name}
        id={input_id(@field.form, @field.field, nil)}
        value=""
      />
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
          for={input_id(@field.form, @field.field, (@field.value != option && option) || nil)}
          class={[
            "flex uppercase text-xs font-semibold items-center  px-2 py-auto cursor-pointer h-10 border-b-2 hover:border-primary hover:text-primary/80",
            (@field.value == option && "text-primary border-primary") || "border-transparent"
          ]}
        >
          {option}
        </label>
      </div>
    </div>
    """
  end
end
