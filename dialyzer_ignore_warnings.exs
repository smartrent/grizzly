[
  # {"The call _@2:'command'() requires that _@2 is of type atom() not binary()"}
  {"lib/grizzly/connections/async_connection.ex"},
  {"lib/grizzly/connections/sync_connection.ex"},
  # ignore warnings in UUID16 as they are from a bug in Elixir typespecs that
  # has been fixed but not release: https://github.com/elixir-lang/elixir/pull/11449
  # Once a new release (> v1.13.3) is ready we should remove this ignore.
  {"lib/grizzly/zwave/smart_start/meta_extension/uuid16.ex"}
]
