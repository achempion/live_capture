defmodule LiveCapture.LiveRender do
  require EEx

  def as_heex(component_module, template, bindings \\ [assigns: %{}]) do
    caller = %{__ENV__ | module: component_module}

    quoted =
      EEx.compile_string(template,
        engine: Phoenix.LiveView.TagEngine,
        subengine: Phoenix.LiveView.Engine,
        caller: caller,
        file: "inline_heex",
        source: template,
        tag_handler: Phoenix.LiveView.HTMLEngine
      )

    env =
      Map.merge(__ENV__, %{
        requires: [Kernel],
        aliases: eval_aliases(component_module),
        functions: eval_functions(component_module),
        macros: [{Kernel, Kernel.__info__(:macros)}]
      })

    {rendered, _, _} = Code.eval_quoted_with_env(quoted, bindings, env)

    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp eval_aliases(component_module) do
    default_aliases = [component_module, Phoenix.LiveView.JS]

    for mod <- default_aliases, reduce: [] do
      acc ->
        alias_name = :"Elixir.#{mod |> Module.split() |> List.last()}"
        if alias_name == mod, do: acc, else: [{alias_name, mod} | acc]
    end
  end

  defp eval_functions(component_module) do
    base = [
      {Phoenix.Component, Phoenix.Component.__info__(:functions)},
      {Kernel, Kernel.__info__(:functions)},
      {component_module, component_module.__info__(:functions)}
    ]

    base
  end
end
