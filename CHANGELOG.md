# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v9.1.2]

### Fixed

* Fix minor bugs in OTW update runner ([#1230](https://github.com/smartrent/grizzly/pull/1230))

## [v9.1.1]

### Fixed

* Fix OTW update runner issues when Z/IP Gateway is not available ([#1227](https://github.com/smartrent/grizzly/pull/1227))
* Reduce default DTLS connect and handshake timeouts to 1s ([#1228](https://github.com/smartrent/grizzly/pull/1228))

## [v9.1.0]

### Removed

* `Grizzly.BackgroundRSSIMonitor` has been removed ([#1214](https://github.com/smartrent/grizzly/pull/1214))

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

[v9.1.2]: https://github.com/smartrent/grizzly/compare/v9.1.1..v9.1.2
[v9.1.1]: https://github.com/smartrent/grizzly/compare/v9.1.0..v9.1.1
[v9.1.0]: https://github.com/smartrent/grizzly/compare/v9.0.0..v9.1.0
[v9.0.0]: https://github.com/smartrent/grizzly/compare/v8.15.3..v9.0.0
