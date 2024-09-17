defmodule CaptureUI.Main.ShowLive do
  use Phoenix.LiveView

  def mounted(_, _, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"Hello world"
  end
end
