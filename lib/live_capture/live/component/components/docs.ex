defmodule LiveCapture.Component.Components.Docs do
  use Phoenix.Component
  import Phoenix.HTML, only: [raw: 1]

  @theme %{
    colors: %{
      wrapper_bg: "bg-white",
      wrapper_text: "text-slate-900",
      keyword: "text-indigo-600",
      module: "text-sky-700",
      function: "text-emerald-700",
      attr_name: "text-amber-700",
      operator: "text-slate-500",
      value: "text-slate-800",
      string: "text-orange-700",
      atom: "text-fuchsia-700",
      number: "text-emerald-700",
      punctuation: "text-slate-500",
      default: "text-slate-700"
    }
  }

  attr :component, :map,
    required: true,
    examples: [
      %{
        module: LiveCapture.Component.Components.Example,
        function: :hello_world,
        attrs: [%{name: :title, opts: [examples: ["Earth"]]}]
      }
    ]

  def show(assigns) do
    module_name =
      assigns.component.module
      |> to_string()
      |> String.replace_prefix("Elixir.", "")

    aliased_name =
      module_name
      |> String.split(".")
      |> List.last()

    assigns =
      assigns
      |> assign(:module_name, module_name)
      |> assign(:aliased_name, aliased_name)

    ~H"""
    <div
      class={[
        "block rounded-lg p-4 font-mono text-sm leading-relaxed",
        color(:wrapper_bg),
        color(:wrapper_text)
      ]}
      phx-no-format
    >
      <.alias_line module_name={@module_name} />
      <div><br /></div>
      <.component_call aliased_name={@aliased_name} component={@component} />
    </div>
    """
  end

  defp alias_line(assigns) do
    ~H"""
    <div><%= highlight("alias ", :keyword) %><%= highlight(@module_name, :module) %></div>
    """
  end

  defp component_call(assigns) do
    assigns =
      assigns
      |> assign(:function_name, assigns.component[:function] |> to_string())
      |> assign(:attr_list, attr_examples(assigns.component[:attrs]))
      |> assign(:slots, slot_examples(assigns.component))

    ~H"""
    <%= if @attr_list == [] and @slots == [] do %>
      <div>
        <%= highlight("<", :punctuation) %><%= highlight(@aliased_name, :module) %>.<%= highlight(
          @function_name,
          :function
        ) %><%= highlight(" />", :punctuation) %>
      </div>
    <% else %>
      <div>
        <%= highlight("<", :punctuation) %><%= highlight(@aliased_name, :module) %>.<%= highlight(
          @function_name,
          :function
        ) %>
      </div>
      <.attrs :if={@attr_list != []} list={@attr_list} />
      <%= if @slots == [] do %>
        <div><%= highlight("/>", :punctuation) %></div>
      <% else %>
        <div><%= highlight(">", :punctuation) %></div>
        <.slot_calls slots={@slots} />
        <div>
          <%= highlight("</", :punctuation) %><%= highlight(@aliased_name, :module) %>.<%= highlight(
            @function_name,
            :function
          ) %><%= highlight(">", :punctuation) %>
        </div>
      <% end %>
    <% end %>
    """
  end

  defp attrs(assigns) do
    assigns = assign(assigns, :attrs, assigns.list || [])

    ~H"""
    <div class="ml-4">
      <%= for {name, example} <- @attrs do %>
        <%= if multiline_value?(example) do %>
          <div>
            <%= highlight(name, :attr_name) %><%= highlight("=", :operator) %><%= highlight(
              "{",
              :punctuation
            ) %>
          </div>
          <%= render_value_lines(example, 2) %>
          <div><%= highlight("}", :punctuation) %></div>
        <% else %>
          <div>
            <%= highlight(name, :attr_name) %><%= highlight("=", :operator) %><%= render_inline(
              example
            ) %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp attr_examples(list) do
    (list || [])
    |> Enum.flat_map(fn
      %{name: name, opts: opts} ->
        opts = opts || []

        cond do
          Keyword.has_key?(opts, :examples) ->
            case Keyword.get(opts, :examples, []) do
              [example | _] -> [{name, example}]
              _ -> []
            end

          Keyword.has_key?(opts, :default) ->
            [{name, Keyword.get(opts, :default)}]

          true ->
            []
        end

      _ ->
        []
    end)
  end

  defp slot_examples(component) do
    defs = normalize_slot_defs(component[:slots])
    examples = component[:slot_examples] || %{}

    Enum.map(defs, fn slot_def ->
      name = slot_def[:name]
      entry_examples = Map.get(examples, name)
      attrs = attr_examples(slot_def[:attrs])

      entries =
        slot_entries(entry_examples)
        |> default_entries(attrs)
        |> Enum.map(&populate_entry_attrs(&1, attrs))

      %{name: name, entries: entries}
    end)
  end

  defp normalize_slot_defs(nil), do: []

  defp normalize_slot_defs(slots) when is_map(slots) do
    slots
    |> Enum.map(fn {name, spec} ->
      spec = spec || %{}
      spec = if is_map(spec), do: spec, else: %{}
      Map.put_new(spec, :name, name)
    end)
  end

  defp normalize_slot_defs(slots) when is_list(slots) do
    slots |> Enum.map(&Map.put_new(&1, :name, &1[:name]))
  end

  defp normalize_slot_defs(_), do: []

  defp slot_entries(nil), do: []

  defp slot_entries(entries) when is_list(entries) do
    Enum.map(entries, &normalize_slot_entry/1)
  end

  defp slot_entries(entry) do
    [normalize_slot_entry(entry)]
  end

  defp normalize_slot_entry(%{} = entry) do
    {content, attrs} =
      if Map.has_key?(entry, :content) do
        {Map.get(entry, :content), Map.delete(entry, :content)}
      else
        {nil, entry}
      end

    %{attrs: attrs || %{}, content: content}
  end

  defp normalize_slot_entry(entry) do
    %{attrs: %{}, content: entry}
  end

  defp default_entries([], attrs), do: [%{attrs: %{}, content: default_content(attrs)}]
  defp default_entries(entries, _attrs), do: entries

  defp default_content(_attrs), do: []

  defp populate_entry_attrs(%{attrs: attr_map} = entry, attr_examples) do
    attr_map = attr_map || %{}

    attrs_from_entry =
      attr_map
      |> Enum.map(fn {name, value} -> {name, value} end)

    attrs_from_examples =
      attr_examples
      |> Enum.reject(fn {name, _example} -> Map.has_key?(attr_map, name) end)

    attrs =
      (attrs_from_entry ++ attrs_from_examples)
      |> Enum.filter(fn {_name, value} -> value != nil end)

    Map.put(entry, :attrs, attrs)
  end

  defp slot_calls(assigns) do
    ~H"""
    <div class="ml-4">
      <%= for slot <- @slots do %>
        <%= for entry <- slot.entries do %>
          <div>
            <%= highlight("  <:#{slot.name}", :punctuation) %><%= slot_attrs(entry.attrs) %><%=
              highlight(">", :punctuation)
            %>
          </div>
          <%= slot_content(entry.content, 2) %>
          <div><%= highlight("  </:#{slot.name}>", :punctuation) %></div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp slot_attrs(attrs) do
    attrs
    |> Enum.flat_map(fn {name, value} ->
      [" ", highlight_token(name, :attr_name), highlight_token("=", :operator), render_inline(value)]
    end)
  end

  defp slot_content(nil, _indent), do: raw("")

  defp slot_content(content, indent) when is_binary(content) do
    padding = String.duplicate("&nbsp;", indent)
    raw(["<div>", padding, Phoenix.HTML.Safe.to_iodata(highlight_token(content, :string)), "</div>"])
  end

  defp slot_content(content, indent) do
    content
    |> value_lines(indent)
    |> lines_to_html()
  end

  defp highlight(text, category) do
    assigns = %{text: to_string(text), classes: category_classes(category)}

    ~H"""
    <span class={@classes}><%= @text %></span>
    """
  end

  defp highlight(value) do
    value
    |> value_lines(0)
    |> lines_to_html()
  end

  defp render_value_lines(value, indent) do
    value
    |> value_lines(indent)
    |> lines_to_html()
  end

  defp render_inline(value) do
    value
    |> value_lines(0)
    |> inline_tokens()
    |> raw()
  end

  defp multiline_value?(value) when is_map(value) or is_list(value) or is_tuple(value), do: true
  defp multiline_value?(%_{}), do: true
  defp multiline_value?(_), do: false

  defp value_lines(value, indent) when is_binary(value) do
    [
      {indent,
       [
         highlight_token("\"", :punctuation),
         highlight_token(value, :string),
         highlight_token("\"", :punctuation)
       ]}
    ]
  end

  defp value_lines(value, indent) when is_atom(value) do
    [{indent, [highlight_token(":", :operator), highlight_token(Atom.to_string(value), :atom)]}]
  end

  defp value_lines(value, indent) when is_integer(value) or is_float(value) do
    [{indent, [highlight_token(to_string(value), :number)]}]
  end

  defp value_lines(list, indent) when is_list(list) do
    cond do
      list == [] ->
        [{indent, [highlight_token("[]", :punctuation)]}]

      long_list?(list) ->
        collapsible_list(list, indent)

      true ->
        list_lines(list, indent)
    end
  end

  defp list_lines(list, indent) do
    if inline_list?(list) do
      parts =
        list
        |> Enum.map(&value_lines(&1, 0))
        |> Enum.map(&lines_to_tokens/1)
        |> Enum.intersperse(highlight_token(", ", :punctuation))

      [{indent, [highlight_token("[", :punctuation), parts, highlight_token("]", :punctuation)]}]
    else
      open = {indent, [highlight_token("[", :punctuation)]}

      inner =
        list
        |> Enum.with_index()
        |> Enum.flat_map(fn {item, idx} ->
          suffix = if idx < length(list) - 1, do: highlight_token(",", :punctuation), else: nil
          item |> value_lines(indent + 2) |> append_suffix(suffix)
        end)

      close = {indent, [highlight_token("]", :punctuation)]}
      [open | inner] ++ [close]
    end
  end

  defp value_lines(%struct{} = value, indent) do
    module =
      struct
      |> Module.split()
      |> List.last()

    fields = Map.from_struct(value) |> Enum.to_list()

    open =
      {indent,
       [
         highlight_token("%", :operator),
         highlight_token(module, :module),
         highlight_token("{", :punctuation)
       ]}

    inner = render_pairs(fields, indent + 2)
    close = {indent, [highlight_token("}", :punctuation)]}

    collapsible_struct(module, [open | inner] ++ [close], indent)
  end

  defp value_lines(map, indent) when is_map(map) do
    if map == %{} do
      [{indent, [highlight_token("%{}", :punctuation)]}]
    else
      map_lines(map, indent)
    end
  end

  defp map_lines(map, indent) do
    pairs = map |> Enum.to_list()
    open = {indent, [highlight_token("%{", :punctuation)]}
    inner = render_pairs(pairs, indent + 2)
    close = {indent, [highlight_token("}", :punctuation)]}

    [open | inner] ++ [close]
  end

  defp value_lines({a, b}, indent) do
    open = {indent, [highlight_token("{", :punctuation)]}

    inner =
      [{a, 0}, {b, 1}]
      |> Enum.flat_map(fn {item, idx} ->
        suffix = if idx == 0, do: highlight_token(", ", :punctuation), else: nil
        item |> value_lines(indent + 2) |> append_suffix(suffix)
      end)

    close = {indent, [highlight_token("}", :punctuation)]}
    [open | inner] ++ [close]
  end

  defp value_lines(value, indent) do
    [{indent, [highlight_token(inspect(value), :value)]}]
  end

  defp render_pairs(pairs, indent) do
    total = length(pairs)

    pairs
    |> Enum.with_index()
    |> Enum.flat_map(fn {{k, v}, idx} ->
      suffix = if idx < total - 1, do: highlight_token(",", :punctuation), else: nil
      render_pair(k, v, indent, suffix)
    end)
  end

  defp render_pair(key, value, indent, suffix) do
    lines = value_lines(value, indent)

    case lines do
      [{_child_indent, parts} | rest] ->
        new_first =
          {indent,
           key_tokens(key) ++
             [highlight_token(": ", :operator)] ++ parts}

        [new_first | rest] |> append_suffix(suffix)

      _ ->
        append_suffix([{indent, key_tokens(key) ++ [highlight_token(": ", :operator)]}], suffix)
    end
  end

  defp lines_to_tokens(lines) do
    case lines do
      [{_indent, parts}] ->
        parts

      _ ->
        lines
        |> lines_to_html()
        |> Phoenix.HTML.Safe.to_iodata()
    end
  end

  defp lines_to_html(lines) do
    iodata =
      lines
      |> Enum.map(&line_to_html/1)

    raw(iodata)
  end

  defp line_to_html({:collapsible, indent, label_tokens, inner_lines}) do
    render_collapsible(label_tokens, indent, inner_lines)
  end

  defp line_to_html({indent, parts}) do
    padding = String.duplicate("&nbsp;", indent)
    content = parts |> List.wrap() |> Enum.map(&Phoenix.HTML.Safe.to_iodata/1)
    ["<div>", padding, content, "</div>"]
  end

  defp inline_tokens([{_indent, parts}]) do
    parts
    |> List.wrap()
    |> Enum.map(&Phoenix.HTML.Safe.to_iodata/1)
  end

  defp append_suffix(lines, nil), do: lines

  defp append_suffix([], _suffix), do: []

  defp append_suffix(lines, suffix) do
    {indent, parts} = List.last(lines)
    List.replace_at(lines, -1, {indent, parts ++ [suffix]})
  end

  defp inline_list?(list) do
    short? = length(list) <= 5
    simple? = Enum.all?(list, &(!multiline_value?(&1)))
    short? and simple?
  end

  defp key_tokens(key) when is_atom(key) do
    [highlight_token(Atom.to_string(key), :atom)]
  end

  defp key_tokens(key) when is_binary(key) do
    [
      highlight_token("\"", :punctuation),
      highlight_token(key, :string),
      highlight_token("\"", :punctuation)
    ]
  end

  defp key_tokens(key), do: [highlight_token(inspect(key), :value)]

  defp highlight_token(text, category) do
    escaped =
      text
      |> to_string()
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.Safe.to_iodata()

    class =
      category_classes(category)
      |> Enum.join(" ")

    {:safe, ["<span class=\"", class, "\">", escaped, "</span>"]}
  end

  defp category_classes(category) do
    tone = color(category)

    ["docs-syntax", tone]
  end

  defp collapsible(label_tokens, lines, indent) do
    [{:collapsible, indent, label_tokens, lines}]
  end

  defp render_collapsible(label_tokens, indent, inner_lines) do
    base_id = "docs-collapsible-#{System.unique_integer([:positive])}"
    label_id = base_id <> "-label"
    content_id = base_id <> "-content"

    toggle =
      "document.getElementById('#{content_id}').classList.remove('hidden');" <>
        "document.getElementById('#{label_id}').classList.add('hidden');"

    margin_left =
      if indent > 0 do
        [" style=\"margin-left: ", Integer.to_string(indent), "ch\""]
      else
        []
      end

    [
      "<div><span id=\"",
      label_id,
      "\" class=\"inline-block cursor-pointer rounded bg-slate-100 px-1 text-[11px] leading-5\"",
      margin_left,
      " onclick=\"",
      toggle,
      "\">",
      label_tokens |> Enum.map(&Phoenix.HTML.Safe.to_iodata/1),
      "</span>",
      "</div>",
      "<div id=\"",
      content_id,
      "\" class=\"hidden\">",
      Phoenix.HTML.Safe.to_iodata(lines_to_html(inner_lines)),
      "</div>"
    ]
  end

  defp collapsible_struct(module, lines, indent) do
    collapsible(struct_label_tokens(module), lines, indent)
  end

  defp collapsible_list(list, indent) do
    label_tokens = [
      highlight_token("[", :punctuation),
      highlight_token("...", :punctuation),
      highlight_token("]", :punctuation)
    ]

    collapsible(label_tokens, list_lines(list, indent), indent)
  end

  defp struct_label_tokens(module) do
    [
      highlight_token("%", :operator),
      highlight_token(module, :module),
      highlight_token("{", :punctuation),
      highlight_token("...", :punctuation),
      highlight_token("}", :punctuation)
    ]
  end

  defp long_list?(list) do
    list
    |> inspect()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> String.length()
    |> Kernel.>(100)
  end

  defp color(category), do: Map.get(@theme.colors, category, @theme.colors[:default])
end
