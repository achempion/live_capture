defmodule CaptureUI.Main.ShowLive do
  use CaptureUI.Web, :live_view

  def mounted(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="text-zinc-800 bg-[red]">Hi test</div>
    """
  end
end
