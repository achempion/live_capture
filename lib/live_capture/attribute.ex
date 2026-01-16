defmodule LiveCapture.Attribute do
  defstruct [:resolver]

  def with_csp_nounces(resolver) when is_function(resolver, 1) do
    %__MODULE__{resolver: resolver}
  end

  def resolve(%__MODULE__{resolver: resolver}, conn_assigns) do
    resolver.(conn_assigns || %{})
  end

  def resolve(value, _conn_assigns), do: value
end
