defmodule LiveCapture.Component.Components.Docs do
  use Phoenix.Component
  import Phoenix.HTML, only: [raw: 1]
  alias LiveCapture.Component

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
    <div>{highlight("alias ", :keyword)}{highlight(@module_name, :module)}</div>
    """
  end

  defp component_call(assigns) do
    attr_values = example_attrs(assigns.component)
    slot_entries = example_slots(assigns.component)

    assigns =
      assigns
      |> assign(:function_name, assigns.component[:function] |> to_string())
      |> assign(:attr_list, attr_values)
      |> assign(:slot_data, slot_examples(assigns.component[:slots], slot_entries))

    ~H"""
    <%= if @attr_list == [] and @slot_data.named == [] and @slot_data.default == [] do %>
      <div>
        {highlight("<", :punctuation)}{highlight(@aliased_name, :module)}.{highlight(
          @function_name,
          :function
        )}{highlight(" />", :punctuation)}
      </div>
    <% else %>
      <div>
        {highlight("<", :punctuation)}{highlight(@aliased_name, :module)}.{highlight(
          @function_name,
          :function
        )}
      </div>
      <.attrs :if={@attr_list != []} list={@attr_list} />
      <%= if @slot_data.named == [] and @slot_data.default == [] do %>
        <div>{highlight("/>", :punctuation)}</div>
      <% else %>
        <div>{highlight(">", :punctuation)}</div>
        <div class="ml-4">
          <.slot_calls slots={@slot_data.named} />
          {default_slot_content(@slot_data.default)}
        </div>
        <div>
          {highlight("</", :punctuation)}{highlight(@aliased_name, :module)}.{highlight(
            @function_name,
            :function
          )}{highlight(">", :punctuation)}
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
            {highlight(name, :attr_name)}{highlight("=", :operator)}<%= highlight(
              "{",
              :punctuation
            ) %>
          </div>
          {render_value_lines(example, 2)}
          <div><%= highlight("}", :punctuation) %></div>
        <% else %>
          <div>
            {highlight(name, :attr_name)}{highlight("=", :operator)}{render_inline(example)}
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp example_attrs(component) do
    Component.attrs(component.module, component.function, component[:variant])
  end

  defp example_slots(component) do
    Component.slots(component.module, component.function, component[:variant])
  end

  defp attr_examples(list, example_values) do
    (list || [])
    |> Enum.flat_map(fn
      %{name: name} ->
        case Map.fetch(example_values || %{}, name) do
          {:ok, value} -> [{name, value}]
          :error -> []
        end

      _ ->
        []
    end)
  end

  defp slot_examples(slot_defs, slot_entries) do
    slot_defs = normalize_slot_defs(slot_defs)
    slot_entries = slot_entries || %{}

    named =
      slot_defs
      |> Enum.map(fn slot_def ->
        entries =
          slot_entries
          |> Map.get(slot_def.name, [])
          |> Enum.map(&slot_entry_example(&1, slot_def[:attrs]))

        %{name: slot_def.name, entries: entries}
      end)
      |> Enum.reject(fn %{entries: entries} -> entries == [] end)

    default_entries =
      slot_entries
      |> Map.get(:inner_block, [])
      |> Enum.map(&slot_entry_example(&1, []))
      |> Enum.reject(&empty_content?/1)

    %{
      named: named,
      default: default_entries
    }
  end

  defp slot_entry_example(entry, attr_defs) do
    %{
      attrs: slot_entry_attrs(entry, attr_defs),
      content:
        entry
        |> slot_entry_content()
        |> normalize_slot_example_content()
    }
  end

  defp slot_entry_attrs(entry, attr_defs) do
    attr_defs = attr_defs || []
    names = Enum.map(attr_defs, & &1[:name])

    ordered =
      names
      |> Enum.flat_map(fn name ->
        case Map.fetch(entry, name) do
          {:ok, value} when value != nil -> [{name, value}]
          _ -> []
        end
      end)

    extras =
      entry
      |> Map.drop([:__slot__, :inner_block])
      |> Enum.reject(fn {key, _} -> key in names end)
      |> Enum.filter(fn {_name, value} -> value != nil end)

    ordered ++ extras
  end

  defp slot_entry_content(%{inner_block: inner_block} = entry) when is_function(inner_block, 2) do
    inner_block.(%{}, entry)
  end

  defp slot_entry_content(%{inner_block: inner_block}) when is_function(inner_block, 1) do
    inner_block.(%{})
  end

  defp slot_entry_content(%{inner_block: inner_block}) when is_function(inner_block, 0) do
    inner_block.()
  end

  defp slot_entry_content(%{inner_block: inner_block}), do: inner_block
  defp slot_entry_content(_), do: nil

  defp normalize_slot_example_content(content) when is_list(content) do
    if Enum.all?(content, &is_binary/1) do
      Enum.join(content)
    else
      content
    end
  end

  defp normalize_slot_example_content(content), do: content

  defp normalize_slot_defs(nil), do: []

  defp normalize_slot_defs(slots) when is_map(slots) do
    slots
    |> Enum.map(fn {name, spec} ->
      spec = spec || %{}
      spec = if is_map(spec), do: spec, else: %{}
      Map.put_new(spec, :name, name)
    end)
    |> Enum.reject(&(&1[:name] == :inner_block))
  end

  defp normalize_slot_defs(slots) when is_list(slots) do
    slots
    |> Enum.map(&Map.put_new(&1, :name, &1[:name]))
    |> Enum.reject(&(&1[:name] == :inner_block))
  end

  defp normalize_slot_defs(_), do: []

  defp slot_calls(assigns) do
    ~H"""
    <%= for slot <- @slots do %>
      <%= for entry <- slot.entries do %>
        <div>
          {highlight("  <:#{slot.name}", :punctuation)}{slot_attrs(entry.attrs)}{highlight(
            ">",
            :punctuation
          )}
        </div>
        {slot_content(entry.content, 2)}
        <div>{highlight("  </:#{slot.name}>", :punctuation)}</div>
      <% end %>
    <% end %>
    """
  end

  defp slot_attrs(attrs) do
    attrs
    |> Enum.flat_map(fn {name, value} ->
      [
        " ",
        highlight_token(name, :attr_name),
        highlight_token("=", :operator),
        render_inline(value)
      ]
    end)
  end

  defp slot_content(nil, _indent), do: raw("")

  defp slot_content(content, indent) when is_binary(content) do
    padding = String.duplicate("&nbsp;", indent)

    raw([
      "<div>",
      padding,
      Phoenix.HTML.Safe.to_iodata(highlight_token(content, :string)),
      "</div>"
    ])
  end

  defp slot_content(content, indent) do
    content
    |> value_lines(indent)
    |> lines_to_html()
  end

  defp default_slot_content([]), do: raw("")

  defp default_slot_content(entries) do
    entries
    |> Enum.reject(&empty_content?/1)
    |> Enum.map(fn entry -> slot_content(entry.content, 0) end)
    |> Phoenix.HTML.Safe.to_iodata()
    |> raw()
  end

  defp empty_content?(%{content: content}), do: empty_content?(content)
  defp empty_content?(nil), do: true
  defp empty_content?([]), do: true
  defp empty_content?(""), do: true
  defp empty_content?(_), do: false

  defp slot_content(content, indent) when is_binary(content) do
    padding = String.duplicate("&nbsp;", indent)

    raw([
      "<div>",
      padding,
      Phoenix.HTML.Safe.to_iodata(highlight_token(content, :string)),
      "</div>"
    ])
  end

  defp slot_content(content, indent) do
    content
    |> value_lines(indent)
    |> lines_to_html()
  end

  defp highlight(text, category) do
    assigns = %{text: to_string(text), classes: category_classes(category)}

    ~H"""
    <span class={@classes}>{@text}</span>
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
      [{:collapsible, _child_indent, _prefix_tokens, label_tokens, inner_lines}] ->
        prefix_tokens = key_tokens(key) ++ [highlight_token(": ", :operator)]

        [{:collapsible, indent, prefix_tokens, label_tokens, inner_lines}]
        |> append_suffix(suffix)

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

  defp line_to_html({:collapsible, indent, prefix_tokens, label_tokens, inner_lines}) do
    adjusted_inner = prepend_prefix_to_inner_lines(inner_lines, prefix_tokens, indent)
    render_collapsible(prefix_tokens, label_tokens, indent, adjusted_inner)
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

  defp append_suffix([{:collapsible, indent, prefix_tokens, label_tokens, inner_lines}], suffix) do
    [
      {:collapsible, indent, prefix_tokens, label_tokens ++ [suffix],
       append_suffix(inner_lines, suffix)}
    ]
  end

  defp append_suffix(lines, suffix) do
    {indent, parts} = List.last(lines)
    List.replace_at(lines, -1, {indent, parts ++ [suffix]})
  end

  defp prepend_prefix_to_inner_lines(inner_lines, [], _indent), do: inner_lines
  defp prepend_prefix_to_inner_lines([], _prefix_tokens, _indent), do: []

  defp prepend_prefix_to_inner_lines(
         [{:collapsible, _child_indent, _, _, _} | _] = lines,
         _prefix_tokens,
         _indent
       ) do
    lines
  end

  defp prepend_prefix_to_inner_lines([{line_indent, parts} | rest], prefix_tokens, _indent) do
    [{line_indent, prefix_tokens ++ parts} | rest]
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

  defp collapsible(label_tokens, lines, indent, prefix_tokens \\ []) do
    [{:collapsible, indent, prefix_tokens, label_tokens, lines}]
  end

  defp render_collapsible(prefix_tokens, label_tokens, indent, inner_lines) do
    base_id = "docs-collapsible-#{System.unique_integer([:positive])}"
    container_id = base_id <> "-container"
    label_id = base_id <> "-label"
    content_id = base_id <> "-content"

    toggle =
      "document.getElementById('#{content_id}').classList.remove('hidden');" <>
        "document.getElementById('#{container_id}').classList.add('hidden');"

    margin_left_attr =
      if indent > 0 do
        [" style=\"margin-left: ", Integer.to_string(indent), "ch\""]
      else
        []
      end

    [
      "<div id=\"",
      container_id,
      "\"",
      margin_left_attr,
      ">",
      Phoenix.HTML.Safe.to_iodata(prefix_tokens),
      "<span id=\"",
      label_id,
      "\" class=\"inline-block cursor-pointer rounded bg-slate-100 px-1 text-[11px] leading-5\"",
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
    try do
      list
      |> inspect()
      |> Code.format_string!()
      |> IO.iodata_to_binary()
      |> String.graphemes()
      |> Enum.count(&(&1 == "\n"))
      |> Kernel.>(4)
    rescue
      _ ->
        list
        |> inspect()
        |> String.length()
        |> Kernel.>(50)
    end
  end

  defp color(category), do: Map.get(@theme.colors, category, @theme.colors[:default])
end
