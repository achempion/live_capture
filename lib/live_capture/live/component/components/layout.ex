defmodule LiveCapture.Component.Components.Layout do
  use Phoenix.Component

  alias LiveCapture.Component.Components

  attr :component, :map, default: nil

  slot :sidebar
  slot :header
  slot :docs
  slot :render

  def show(assigns) do
    ~H"""
    <div class="flex min-h-svh">
      <div class="bg-slate-100 border-r">
        <div class="h-10 flex items-center">
          <div class="font-semibold px-2">
            <.link navigate="/">LiveCapture</.link>
          </div>
        </div>

        <%= render_slot(@sidebar) %>
      </div>

      <div class="flex-1 flex flex-col">
        <div class="border-b flex">
          <div class="h-10 flex items-center justify-end flex-1">
            <%= render_slot(@header) %>
          </div>
        </div>

        <div class="flex-1 bg-slate-100 relative overflow-scroll">
          <%= render_slot(@render) %>
        </div>

        <div class="border-t flex">
          <.section title="Docs">
            <%= render_slot(@docs) %>
          </.section>

          <div class="border-l"></div>

          <.section title="Attributes">
            <form phx-change="change" class="p-4">
              <Components.Attribute.list
                :if={@component[:attrs]}
                attrs={@component[:attrs]}
                custom_params={@component[:custom_params]}
              />
            </form>
          </.section>
        </div>
      </div>
    </div>
    """
  end

  defp section(assigns) do
    ~H"""
    <div class="flex-1 px-2 pt-2 pb-4 max-w-[50%] overflow-scroll">
      <.title title={@title} />
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp title(assigns) do
    ~H"""
    <div class="text-xs font-semibold uppercase text-secondary"><%= @title %></div>
    """
  end
end
