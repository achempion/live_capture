defmodule LiveCapture.Component.Components.Layout do
  use Phoenix.Component

  slot :sidebar
  slot :header
  slot :docs
  slot :attributes
  slot :render

  def show(assigns) do
    ~H"""
    <div class="flex min-h-svh max-h-svh">
      <div class="bg-slate-100 border-r flex flex-col">
        <div class="h-10 flex items-center">
          <div class="font-semibold px-2">
            <.link navigate="/">LiveCapture</.link>
          </div>
        </div>

        <div class="flex-1 overflow-y-auto">
          {render_slot(@sidebar)}
        </div>
      </div>

      <div class="flex-1 flex flex-col">
        <div class="border-b flex">
          <div class="h-10 flex items-center justify-end flex-1">
            {render_slot(@header)}
          </div>
        </div>

        <div class="flex-1 bg-slate-100 relative overflow-scroll">
          {render_slot(@render)}
        </div>

        <div class="border-t flex max-h-[40svh]">
          <.section title="Docs">
            {render_slot(@docs)}
          </.section>

          <div class="border-l"></div>

          <.section :if={false} title="Attributes">
            {render_slot(@attributes)}
          </.section>
        </div>
      </div>
    </div>
    """
  end

  defp section(assigns) do
    ~H"""
    <div class="flex-1 px-2 pt-2 pb-4 overflow-scroll">
      <.title title={@title} />
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp title(assigns) do
    ~H"""
    <div class="text-xs font-semibold uppercase text-secondary">{@title}</div>
    """
  end
end
