# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v9.1.5]

### Changed

* Migrate CI from CircleCI to GitHub Actions ([#1259](https://github.com/smartrent/grizzly/pull/1259))
* Migrate from asdf to mise ([#1254](https://github.com/smartrent/grizzly/pull/1254))
* Adjust CI to create release notes after release is merged in ([#1251](https://github.com/smartrent/grizzly/pull/1251))

### Fixed 

* Fix z-wave event types `messaging_user_code_entered_via_keypad` and `non_access_credential_used` not allowed when decoding access control event params ([#1258](https://github.com/smartrent/grizzly/pull/1258))
* Fix Elixir 1.20 warnings for bin pattern matching `size(pinned)` and unused `require Logger` statements ([#1262](https://github.com/smartrent/grizzly/pull/1262))
* Fix `progress_timer` not created when dispatching initial fw update async command ([#1261](https://github.com/smartrent/grizzly/pull/1261))
* Fix firmware update timeouts conflated with nack responses from devices ([#1260](https://github.com/smartrent/grizzly/pull/1260))

## [v9.1.4]

### Changed

* Fix crash on decoding a thermostat mode report ([#1246](https://github.com/smartrent/grizzly/pull/1246))

## [v9.1.3]

### Changed

* Add helper to clear ZGW S2 span table ([#1232](https://github.com/smartrent/grizzly/pull/1232))
* ENG: Update Trace/Trace.Record output ([#1239](https://github.com/smartrent/grizzly/pull/1239))

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

[v9.1.5]: https://github.com/smartrent/grizzly/compare/v9.1.4..v9.1.5
[v9.1.4]: https://github.com/smartrent/grizzly/compare/v9.1.3..v9.1.4
[v9.1.3]: https://github.com/smartrent/grizzly/compare/v9.1.2..v9.1.3
[v9.1.2]: https://github.com/smartrent/grizzly/compare/v9.1.1..v9.1.2
[v9.1.1]: https://github.com/smartrent/grizzly/compare/v9.1.0..v9.1.1
[v9.1.0]: https://github.com/smartrent/grizzly/compare/v9.0.0..v9.1.0
[v9.0.0]: https://github.com/smartrent/grizzly/compare/v8.15.3..v9.0.0
