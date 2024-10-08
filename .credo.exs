# config/.credo.exs
%{
  configs: [
    %{
      name: "default",
      files: %{
        #
        # You can give explicit globs or simply directories.
        # In the latter case `**/*.{ex,exs}` will be used.
        #
        included: [
          "lib/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      strict: true,
      checks: [
        {CredoBinaryPatterns.Check.Consistency.Pattern},
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Warning.LazyLogging, false},
        {Credo.Check.Readability.LargeNumbers, only_greater_than: 86400},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, parens: true},
        {Credo.Check.Warning.RaiseInsideRescue, false},
        {Credo.Check.Design.TagTODO, false},
        {Credo.Check.Refactor.LongQuoteBlocks, []},
        {Credo.Check.Refactor.Nesting, max_nesting: 3},
        {Credo.Check.Readability.ImplTrue, []},

        ### Below are checks we will want to enable at later date ###
        {Credo.Check.Refactor.WithClauses, false},
        {Credo.Check.Refactor.CyclomaticComplexity, false},
        {Credo.Check.Readability.WithSingleClause, false},
        {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig, false}
      ]
    }
  ]
}
