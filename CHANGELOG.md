# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v9.0.0]

### Changed

* OTW firmware updates for the Z-Wave module have been rewritten to use Elixir instead of zw_programmer ([#1142](https://github.com/smartrent/grizzly/pull/1142))
* The deprecated behaviour `Grizzly.StatusReporter` has been removed (use `Grizzly.Events` instead) ([#1144](https://github.com/smartrent/grizzly/pull/1144))
* `Grizzly.Commands.*` has been renamed `Grizzly.Requests.*` to clarify between Z-Wave
  commands and requests to Z/IP Gateway
* Many Z-Wave commands are now encoded/decoded using a generic encoder instead of
  requiring a module and custom encode/decode functions for every single command

## v8.x Changelog

For Grizzly v8 and older, see the [v8 changelog](https://github.com/smartrent/grizzly/blob/maint/v8/CHANGELOG.md).

[v9.0.0]: https://github.com/smartrent/grizzly/compare/v8.15.3..v9.0.0
