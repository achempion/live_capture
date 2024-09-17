defmodule CaptureUI.Web do
  def live_view do
    quote do
      use Phoenix.LiveView
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
