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
      checks: [
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Warning.LazyLogging, false},
        {Credo.Check.Readability.LargeNumbers, only_greater_than: 86400},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, parens: true},
        {Credo.Check.Warning.RaiseInsideRescue, false},
        {Credo.Check.Design.TagTODO, false},

        ### Below are checks we will want to enable at later date ###
        {Credo.Check.Refactor.WithClauses, false},
        {Credo.Check.Refactor.LongQuoteBlocks, false},
        {Credo.Check.Refactor.CyclomaticComplexity, false},
        {Credo.Check.Consistency.SpaceAroundOperators, false}
      ]
    }
  ]
}
