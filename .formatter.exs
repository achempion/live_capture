locals_without_parens = [
  embed_templates: 1,
  embed_templates: 2,
  breakpoints: 1,
  root_layout: 1,
  capture: 1,
  live_capture: 1,
  live_capture: 2,
  live_capture: 3
]

[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
