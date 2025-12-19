[
  inputs: ["{mix,.credo,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:telemetry_registry, :mimic],
  plugins: [Quokka],
  quokka: [
    autosort: [],
    only: [
      :module_directives
    ],
    exclude: [
      :blocks,
      :comment_directives,
      :configs,
      :defs,
      :deprecations,
      :pipes,
      :single_node,
      :tests,
      :nums_with_underscores,
      :inefficient_functions
    ]
  ]
]
