# LiveCapture

<img align="right" width="96" height="96"
     alt="LiveCapture logo"
     src="images/logo-256.svg">

Zero-boilerplate storybook for LiveView components.

Document, preview, and test LiveView components in isolation.

[Explore component libraries](https://captures.captureui.com/) · [Documentation](https://hexdocs.pm/live_capture/readme.html) · [Hex](https://hex.pm/packages/live_capture)

[Watch the talk from Copenhagen Elixir](https://www.youtube.com/watch?v=P-2jct_Im-A)

---

Need help with LiveCapture integration or your LiveView project? [Hire me](https://cal.com/achempion/hire)

---

## Features

 - Render HEEx components with predefined state snapshots
 - Quickly test visual quality by switching between different width breakpoints
 - Explore component documentation with dynamic state inspection
 - Nice DSL with a strong focus on ergonomics and simplicity

## Quick start

Add the `:live_capture` dependency to the `mix.exs` and `.formatter.exs`.

**mix.exs**
```elixir
{:live_capture, "~> 0.2"}
```

**.formatter.exs**
```elixir
[
  import_deps: [:live_capture, ...]
]
```

Define a configuration module.

```elixir
defmodule MyAppWeb.LiveCapture do
  use LiveCapture.Component

  breakpoints s: "480px", m: "768px", l: "1279px", xl: "1600px"
  root_layout {MyAppWeb.LayoutView, :root}
end
```

Mount LiveCapture in `router.ex`.

> [!TIP]
> You can mount multiple configuration modules by passing them as a list instead.

```elixir
import LiveCapture.Router

scope "/" do
  live_capture "/live_capture", MyAppWeb.LiveCapture
end
```

Capture your first component story.

> [!TIP]
> You can place `use MyAppWeb.LiveCapture` next to `use Phoenix.Component` in `my_app_web.ex`.
> This makes the `capture/0`, `capture/1`, and `capture_all/0` macros available in all component files.

```elixir
use MyAppWeb.LiveCapture

capture()

def my_component(assigns) do
  ~H"""
  My component
  """
end
```

Explore the main capture patterns in [example.ex](https://github.com/achempion/live_capture/blob/main/lib/live_capture/live/component/components/example.ex)

## Capture patterns

Calling `use MyAppWeb.LiveCapture` makes three macros available inside your module:
- `capture/0` to simply capture a component
- `capture/1` to capture a component with attributes and state variants
- `capture_all/0` to automatically capture all HEEx components inside the file

### Simple capture with `capture/0`

If you have a component defined with default attributes, you can render it "as is" with a `capture/0` call.

> [!TIP]
> LiveCapture supports two patterns for default attributes: `:default` and `:examples` (with `:examples` taking priority).

```elixir
attr :name, :string, default: "Main", examples: ["Primary", "Secondary"]

capture()

def my_component(assigns), do: ~H"My component: {@name}"
```

### Set attribute values with `capture/1`

`:attributes` key allows you to override any default values defined with `attr` macro

```elixir
attr :name, :string, required: true

capture attributes: %{name: "Main"}

def my_component(assigns), do: ~H"My component: {@name}"
```

### Multiple variants of the same component

`:variants` key allows you to define multiple component state snapshots

```elixir
attr :name, :string, required: true

capture variants: [
          main: %{name: "Main"},
          secondary: %{name: "Secondary"},
        ]

def my_component(assigns), do: ~H"My component: {@name}"
```

### Components with slots

> [!TIP]
> All `:inner_block` strings are treated as regular HEEx templates.

```elixir
slot :header
slot :inner_block, required: true

slot :rows do
  attr :name, :string
end

capture attributes: %{
          header: "This is header slot",
          inner_block: "Content of the inner block {1+2}",
          rows: [
            %{inner_block: "Slot content", name: "Attribute content"}
          ]
        }

def my_component(assigns), do: ~H"..."
```


### Large components with a complex state structure

LiveCapture makes it possible to render live components and capture a visual snapshot of the `render/1` function used by LiveView dynamic components.

```elixir
defmodule MyAppWeb.Profile.ShowLive do
  use MyAppWeb, :live_view
  use MyAppWeb.LiveCapture

  alias MyAppWeb.LiveCaptureFactory

  def mount(_, _, socket), do: {:ok, socket}

  capture attributes: %{
            current_user: LiveCaptureFactory.build(:current_user)
          }

  def render(assigns) do
  ~H"""
  Example of a large HEEx component with a complex state structure
  """
  end
end
```

To declutter the component code, you can move the definition of complex or recurring state values inside the factory module

```elixir
defmodule MyAppWeb.LiveCaptureFactory do
  alias MyApp.Users

  def build(:current_user) do
    %Users.User{id: 1, name: "First Last"}
  end
end
```

It's also possible to move the declaration of the whole variant attributes payload inside the factory.
You can define and arrange factory modules in a way that fits your project structure best.

```elixir
defmodule MyAppWeb.LiveCaptureWebFactory do
  alias MyAppWeb.Profile

  alias MyAppWeb.LiveCaptureFactory

  def build(Profile.ShowLive, :main) do
    %{
      user: LiveCaptureFactory.build(:current_user)
    }
  end
end
```

### Components with scripts and styles that require CSP nonce attribute

Some components render inline scripts and styles that might require a nonce attribute.

```elixir

def style_nonce(nonces), do: nonces.csp_style_nonce
def script_nonce(nonces), do: nonces.csp_script_nonce

capture attributes: %{
          style_nonce: LiveCapture.Attribute.with_csp_nonces(&__MODULE__.style_nonce/1),
          script_nonce: LiveCapture.Attribute.with_csp_nonces(&__MODULE__.script_nonce/1)
        }

def my_component(assigns), do: ~H"..."
```

Update `live_capture/3` with conn assign keys of CSP nonces.

```elixir
live_capture "/live_capture",
             MyAppWeb.LiveCapture,
             csp_nonce_assign_key: %{
               style: :style_csp_nonce,
               script: :script_csp_nonce
             }
```

### Root Layouts with custom conn assigns

The `plugs` option can configure a list of plugs that will be called during the component render.

```elixir
defmodule MyAppWeb.LiveCapture do
  use LiveCapture.Component

  plugs [MyAppWeb.CustomPlug, {MyAppWeb.CustomPlugWithConfig, key: "value"}]
end
```

## License

Copyright (c) 2026 Boris Kuznetsov <me@achempion.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
