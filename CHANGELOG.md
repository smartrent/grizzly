# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v8.7.1] - 2025-03-06

### Fixed

* Increase timeout for `Grizzly.Network.reset_controller/1` to 60 seconds to allow enough time
  for the Default Set command to complete ([#1058](https://github.com/smartrent/grizzly/pull/1058))

## [v8.7.0] - 2025-02-08

### Changed

* Remove the `listening?` node info property ([#1050](https://github.com/smartrent/grizzly/pull/1050))
  * See the PR for more details, but tl;dr this flag was long ago misinterpreted and does not
    actually indicate whether a node is listening

## [v8.6.9] - 2025-02-03

### Added

* Require MuonTrap v1.6.0 for logging improvements ([#1045](https://github.com/smartrent/grizzly/pull/1045))

### Fixed

* Fix module name typos in `Grizzly.ZWave.Decoder` ([#1046](https://github.com/smartrent/grizzly/pull/1046))
* Enforce command names match module names and handler specs ([#1047](https://github.com/smartrent/grizzly/pull/1047))

## [v8.6.8] - 2025-01-20

No changes. Bumped due to an issue when publishing v8.6.7.

## [v8.6.7] - 2025-01-16 **RETIRED**

### Added

* Implement Configuration Default Reset from Config v4 ([#1040](https://github.com/smartrent/grizzly/pull/1040))
* Elixir 1.18 compatibility ([#1041](https://github.com/smartrent/grizzly/pull/1041))

### Fixed

* Fix incorrect command IDs for Config Info Get/Report ([#1039](https://github.com/smartrent/grizzly/pull/1039))

## [v8.6.6] - 2024-12-13

### Added

* Handle incoming Multi Channel Association commands for endpoint associations ([#1029](https://github.com/smartrent/grizzly/pull/1029))

## [v8.6.5] - 2024-12-05

### Fixed

* Handle out-of-order receipt of Version Command Class Reports ([#1027](https://github.com/smartrent/grizzly/pull/1027))

## [v8.6.4] - 2024-11-25

### Added

* Add retry logic to unsolicited server listen call ([#1021](https://github.com/smartrent/grizzly/pull/1021))
* Provide the possible scales for a given sensor type ([#1019](https://github.com/smartrent/grizzly/pull/1019))
* Support alarm reports for Alarm CC v1 ([#1017](https://github.com/smartrent/grizzly/pull/1017))
  * Unknown alarm types and events will be the raw value

### Fixed

* Fix the decoding of `alarm_type_supported_report` when version 1 of alarm types and events are also supported by the device ([#1024](https://github.com/smartrent/grizzly/pull/1024))

## [v8.6.3] - 2024-11-05

### Fixed

* Inclusion Server handles Extended Node Add Status ([#1015](https://github.com/smartrent/grizzly/pull/1015))

## [v8.6.2] - 2024-11-04

### Added

* Add function to get all notification types ([#1005](https://github.com/smartrent/grizzly/pull/1005))
* Forward unsolicited Node Remove Status to inclusion handler ([#1007](https://github.com/smartrent/grizzly/)pull/1007)
* Implement Meter Get v2-6 ([#1012](https://github.com/smartrent/grizzly/pull/1012))

### Fixed

* Inclusion timeout must be at least as long as the S2 bootstrapping timeouts ([#1008](https://github.com/)smartrent/grizzly/pull/1008)
* Send Device Reset Locally notifications before closing connections ([#1009](https://github.com/smartrent/)grizzly/pull/1009)
* Thermostat Setpoint values should be signed ([#1010](https://github.com/smartrent/grizzly/pull/1010))


## [v8.6.1] - 2024-10-21

### Changed

* Use atoms for scale in Sensor Multilevel Get to align with Sensor Multilevel Report ([#1003](https://github.com/smartrent/grizzly/pull/1003))

## [v8.6.0] - 2024-10-17

### Added

* Support finding all endpoints with Multi Channel Endpoint Find and Multi Channel Endpoint Find Report ([#998](https://github.com/smartrent/grizzly/pull/998), [#1000](https://github.com/smartrent/grizzly/pull/1000))
* Add util to get NWI Home Id from DSK ([#1001](https://github.com/smartrent/grizzly/pull/1001))
* Add missing multilevel sensor types ([#995](https://github.com/smartrent/grizzly/pull/995))
* Update Z-Wave XML to 2024A specification ([#981](https://github.com/smartrent/grizzly/pull/981))

### Fixed

* Continue inclusion started by an inclusion controller ([#997](https://github.com/smartrent/grizzly/pull/997))
* Fix another issue with Z/IP Gateway's Node Add Status formatting ([#996](https://github.com/smartrent/grizzly/pull/996))
* Fix association management for certification ([#994](https://github.com/smartrent/grizzly/pull/994))
* Ignore extended CCs when parsing command class lists ([#993](https://github.com/smartrent/grizzly/pull/993))
* Change keys_granted to granted_keys for consistency ([#992](https://github.com/smartrent/grizzly/pull/992))

### Changed

* Use [`thousand_island`](https://github.com/mtrudel/thousand_island) to manage the unsolicited server ([#987](https://github.com/smartrent/grizzly/pull/987))


## [v8.5.3] - 2024-09-23

### Added

* Added missing notification events ([#980](https://github.com/smartrent/grizzly/pull/980))

### Fixed

* Prevent depletion of UnsolicitedServer listen sockets ([#988](https://github.com/smartrent/grizzly/pull/988))
* Fix acknowledged flag sometimes being incorrectly false ([#983](https://github.com/smartrent/grizzly/pull/983))

### Changed

* Traces record node ids instead of IP addresses ([#985](https://github.com/smartrent/grizzly/pull/985))

## [v8.5.2] - 2024-09-11

### Fixed

* Fix parsing of last working route / speed in transmission stats ([#974](https://github.com/smartrent/grizzly/pull/974))
* Use dynamic delays between image fragments during firmware updates ([#975](https://github.com/smartrent/grizzly/pull/975), [#977](https://github.com/smartrent/grizzly/pull/977))
* Wait for previous ack before continuing firmware upload ([#978](https://github.com/smartrent/grizzly/pull/978))

## [v8.5.1] - 2024-09-06

### Added

* Support malformed Thermostat Setpoint Capabilities Report from B36-T10 / ADC-T2000 ([#969](https://github.com/smartrent/grizzly/pull/969))
* Support manufacturer-specific thermostat modes ([#970](https://github.com/smartrent/grizzly/pull/970))

## [v8.5.0] - 2024-08-28

### Added

* Implement Configuration Info Get/Report ([#961](https://github.com/smartrent/grizzly/pull/961))

### Fixed

* Ignore nack_response when updating device firmware instead of crashing ([#966](https://github.com/smartrent/grizzly/pull/966))
* Do not strip Z-Wave LR transmission stats ([#963](https://github.com/smartrent/grizzly/pull/963))
* Handle empty node info in (Extended) Node Add Status ([#964](https://github.com/smartrent/grizzly/pull/964))
* Fix encoding of Node Provisioning Set command ([#962](https://github.com/smartrent/grizzly/pull/962))
* Trim trailing null bytes from User Code Report ([#959](https://github.com/smartrent/grizzly/pull/959))

### Changed

* Remove support for Z/IP Gateway EEPROM migration ([#960](https://github.com/smartrent/grizzly/pull/960))

## [v8.4.0] - 2024-08-05

### Fixed

- Ignore invalid TLV segments when parsing SmartStart codes ([#950](https://github.com/smartrent/grizzly/pull/950))
- Add missing `:more_info` option to `t:Grizzly.command_opt/0` ([#951](https://github.com/smartrent/grizzly/pull/951))
- Fix connection crash when receiving NACK / Queue Full ([#953](https://github.com/smartrent/grizzly/pull/953))
- Quiet down logs when ignoring fw update reports ([#954](https://github.com/smartrent/grizzly/pull/954))
- Remove useless more info flag from ack responses ([#955](https://github.com/smartrent/grizzly/pull/955))
- DTLS listen sockets start in passive mode ([#956](https://github.com/smartrent/grizzly/pull/956))
- Fix Z/IP Gateway log prefix ([#957](https://github.com/smartrent/grizzly/pull/957))

### Changed

- Send a Grizzly.Report for nack responses to queued commands ([#952](https://github.com/smartrent/grizzly/pull/952))

## [v8.3.0] - 2024-07-17

### Changed

- Allow undefined values for user id status ([#946](https://github.com/smartrent/grizzly/pull/946))

## [v8.2.3] - 2024-06-25

### Changed

- Use a fixed log prefix when running Z/IP Gateway ([#942](https://github.com/smartrent/grizzly/pull/942))

## [v8.2.2] - 2024-06-05

### Added

- Elixir 1.17 compatibility ([#935](https://github.com/smartrent/grizzly/pull/935))

### Fixed

- Remove leading space from test in Z/IP Gateway log monitor ([#936](https://github.com/smartrent/grizzly/pull/936))

## [v8.2.1] - 2024-06-03

### Fixed

- Bring the ThermostatOperatingState spec in line with impl ([#933](https://github.com/smartrent/grizzly/pull/933))

## [v8.2.0] - 2024-05-17

### Added

- Implement S0 Command Class ([#899](https://github.com/smartrent/grizzly/pull/899))
- Implement S2 Command Class ([#900](https://github.com/smartrent/grizzly/pull/900))

## [v8.1.0] - 2024-05-02

### Added

- Improve firmware updates for wakeup devices ([#922](https://github.com/smartrent/grizzly/pull/922))
- Implement Included NIF Report command ([#923](https://github.com/smartrent/grizzly/pull/923))
- Allow creation of unnamed `AsyncConnection`s ([#924](https://github.com/smartrent/grizzly/pull/924))
- Fix typo in definition of  `Grizzly.send_command_error` ([#925](https://github.com/smartrent/grizzly/pull/925))

## [v8.0.1] - 2024-04-24

### Fixed

- Allow 4 byte input for Door Lock Operation Report ([#919](https://github.com/smartrent/grizzly/pull/919))

## [v8.0.0] - 2024-04-22

### Breaking Changes

- Virtual devices now have their IDs assigned statically at registration ([#917](https://github.com/smartrent/grizzly/pull/917))

### Added

- Colorize DSKs when inspecting ([#916](https://github.com/smartrent/grizzly/pull/916))

## [v7.4.2] - 2024-04-11

### Fixed

- Stopping an already-stopped CommandRunner no longer raises ([#912](https://github.com/smartrent/grizzly/pull/912))
- Allow any value when decoding battery level ([#913](https://github.com/smartrent/grizzly/pull/913))

## [v7.4.1] - 2024-03-15

### Fixed

- Handle commands timing out or being queued during firmware updates ([#908](https://github.com/smartrent/grizzly/pull/908))

## [v7.4.0] - 2024-02-08

### Added

- Implement Thermostat Setpoint Capabilities Get/Report ([#901](https://github.com/smartrent/grizzly/pull/901))
- Implement Thermostat Fan Mode Supported Get/Report ([#902](https://github.com/smartrent/grizzly/pull/902))

## [v7.3.0] - 2024-02-07

### Added

- Add missing commands to SensorMultilevel CC ([#895](https://github.com/smartrent/grizzly/pull/895))
- Ignore extra trailing bytes when decoding ThermostatSetpointReport ([#896](https://github.com/smartrent/grizzly/pull/896))

### Fixed

- Encode extended node id correctly in `S2ResynchronizationEvent` ([#887](https://github.com/smartrent/grizzly/pull/887))

## [v7.2.0] - 2024-01-30

### Added

- Implement missing Meter CC commands ([#890](https://github.com/smartrent/grizzly/pull/890))
- Use correct security classes for LR in advanced joining option ([#892](https://github.com/smartrent/grizzly/pull/892))

### Fixed

- Fix incorrect match clause in catch ([#893](https://github.com/smartrent/grizzly/pull/893))

## [v7.1.4] - 2024-01-26

### Added

- Hard reset Z-Wave module on Z/IP Gateway exit ([#888](https://github.com/smartrent/grizzly/pull/888))

## [v7.1.3] - 2024-01-09

### Fixed

- Fix more false positives in SAPI status reporting ([#884](https://github.com/smartrent/grizzly/pull/884))

## [v7.1.2] - 2024-01-08

### Fixed

- Support Elixir 1.16 ([#881](https://github.com/smartrent/grizzly/pull/881))

## [v7.1.1] - 2024-01-03

### Fixed

- Remove any() from type send_command_response ([#873](https://github.com/smartrent/grizzly/pull/873))
- Fix false positives in SAPI status reporting ([#879](https://github.com/smartrent/grizzly/pull/879))

## [v7.1.0] - 2023-12-05

### Added

- Implement Humidity Control CCs ([#867](https://github.com/smartrent/grizzly/pull/867))
- UnsolicitedServer includes node id in Logger metadata ([#869](https://github.com/smartrent/grizzly/pull/869))

### Fixed

- Simplify bitmask encoding and decoding ([#866](https://github.com/smartrent/grizzly/pull/866))
- Fix User Code Set when User ID Status is 0x00 ([#868](https://github.com/smartrent/grizzly/pull/868))
Fix Node Add Status parsing when length is off by one ([#871](https://github.com/smartrent/grizzly/pull/871))

## [v7.0.4] - 2023-11-08

### Added

- Record original command binary in Logger metadata ([#864](https://github.com/smartrent/grizzly/pull/864))

## [v7.0.3] - 2023-11-06

### Added

- Report Serial API status ([#861](https://github.com/smartrent/grizzly/pull/861))

### Fixed

- Correct CC name from multi_command to multi_cmd ([#858](https://github.com/smartrent/grizzly/pull/858))
- Grizzly supports v3 of Association Group Info CC ([#859](https://github.com/smartrent/grizzly/pull/859))
- Fix incorrect installation and maintenance header extension name ([#860](https://github.com/smartrent/grizzly/pull/860))
- Catch exits when closing all connections ([#862](https://github.com/smartrent/grizzly/pull/862))

## [v7.0.2] - 2023-10-17

### Added

- Implement Sensor Binary Supported Sensor Get/Report ([#848](https://github.com/smartrent/grizzly/pull/848))
- Decode state_idle event params for all notification types ([#849](https://github.com/smartrent/grizzly/pull/849))

### Fixed

- Suppress DTLS errors for "TLS Alert: unexpected message" ([#845](https://github.com/smartrent/grizzly/pull/845))
- Close all DTLS connections on Z/IP Gateway exit ([#850](https://github.com/smartrent/grizzly/pull/850))

### Misc

- Add `credo_binary_patterns` and adjust patterns to pass ([#847](https://github.com/smartrent/grizzly/pull/847))

## [v7.0.1] - 2023-09-26

### Fixed

- Allow speed to be 0 (unknown/not set) in Priority Route Report ([#842](https://github.com/smartrent/grizzly/pull/842))
- Ignore installation and maintenance report header extension in outgoing Z/IP Packets ([#843](https://github.com/smartrent/grizzly/pull/843))

## [v7.0.0] - 2023-09-25

### Added

- `Grizzly.Inclusions` passes command params through to NodeAdd and SetLearnMode ([#838](https://github.com/smartrent/grizzly/pull/838))
- Implement Priority Route Set command ([#839](https://github.com/smartrent/grizzly/pull/839))

### Changed

- Fix parsing of speed parameter in Priority Route Report ([#839](https://github.com/smartrent/grizzly/pull/839))
- **BREAKING**: Z-Wave module firmware upgrade rewrite ([#840](https://github.com/smartrent/grizzly/pull/840))

## [v6.8.8] - 2023-09-01

### Fixed

- Reports indicate command acknowledgement ([#836](https://github.com/smartrent/grizzly/pull/836))
- Handle `{:error, :timeout}` when getting all node ids ([#835](https://github.com/smartrent/grizzly/pull/835))

### Misc

- Remove dead code from `Grizzly.UnsolicitedServer` ([#832](https://github.com/smartrent/grizzly/pull/832))

## [v6.8.7] - 2023-08-30

### Fixed

- Reply to unsolicited commands on the same DTLS connection ([#827](https://github.com/smartrent/grizzly/pull/827))
- Execute external callbacks in `Task`s ([#830](https://github.com/smartrent/grizzly/pull/830))

## [v6.8.6] - 2023-08-25

### Fixed

- Z/IP Gateway ready checker waits for initial node list report ([#824](https://github.com/smartrent/grizzly/pull/824))
- Rename Master Code commands to Admin Code ([#825](https://github.com/smartrent/grizzly/pull/825))

## [v6.8.5] - 2023-08-21

### Fixed

- Value in Multilevel Sensor Reports should be interpreted as signed ([#817](https://github.com/smartrent/grizzly/pull/817))
- Cap Z-Wave float precision at 7 ([#818](https://github.com/smartrent/grizzly/pull/818))
- Ignore reserved field values when parsing Battery Reports ([#820](https://github.com/smartrent/grizzly/pull/820))
- Ignore trailing bytes in Door Lock Operation Report ([#821](https://github.com/smartrent/grizzly/pull/821))
- Ignore illegal values for door lock mode ([#822](https://github.com/smartrent/grizzly/pull/822))

## [v6.8.4] - 2023-08-07

### Fixed

- Fix response handler for Multi Channel Association Get ([#813](https://github.com/smartrent/grizzly/pull/813))
- Add missing state values to Thermostat Operating State ([#814](https://github.com/smartrent/grizzly/pull/814))
- Fix encoding/decoding for Meter Report v2-5 ([#815](https://github.com/smartrent/grizzly/pull/815))

## [v6.8.3] - 2023-08-01

### Fixed

- Fix `:ack_request` in response to AsyncConnection command ([#810](https://github.com/smartrent/grizzly/pull/810))

## [v6.8.2] - 2023-07-31

### Added

- Implement Sound Switch CC v1-2 ([#806](https://github.com/smartrent/grizzly/pull/806))
- Implement all commands from User Code CC v2 ([#697](https://github.com/smartrent/grizzly/pull/697))

### Fixed

- Fix async command timeout handling ([#808](https://github.com/smartrent/grizzly/pull/808))
- Fix decoding of meter type in Meter Reports ([#807](https://github.com/smartrent/grizzly/pull/807))

## [v6.8.1] - 2023-07-19

### Changed

- Pass trace options through from `Grizzly.Supervisor` ([#803](https://github.com/smartrent/grizzly/pull/803))
- Made network management command arguments more consistent ([#804](https://github.com/smartrent/grizzly/pull/804))

## [v6.8.0] - 2023-07-18

### Added

- Add telemetry ([#751](https://github.com/smartrent/grizzly/pull/751))
- Implement Mailbox Command Class ([#777](https://github.com/smartrent/grizzly/pull/777))
- Allow DTLSv1.2 for Z/IP Gateway connections ([#782](https://github.com/smartrent/grizzly/pull/782))
- Add `:raw` trace format ([#784](https://github.com/smartrent/grizzly/pull/784))
- Add option to ignore keepalive frames in traces ([#785](https://github.com/smartrent/grizzly/pull/785))
- Use Z-Wave XML to generate command class mappings ([#793](https://github.com/smartrent/grizzly/pull/793))
- Add `:mode` option to `Grizzly.send_command/4` ([#795](https://github.com/smartrent/grizzly/pull/795))

### Fixed

- Use correct command module for Wake Up Interval Set in `Grizzly.ZWave.Decoder` ([#798](https://github.com/smartrent/grizzly/pull/798))
- Skip unsupported values when parsing command class lists ([#799](https://github.com/smartrent/grizzly/pull/799))
- Trace `:text` format prints command binary (without Z/IP Packet header) exactly as received ([#800](https://github.com/smartrent/grizzly/pull/800))

## [v6.7.1] - 2023-06-20

### Added

- Added `Grizzly.Network.get_lifeline_association/1` convenience function ([#781](https://github.com/smartrent/grizzly/pull/781))

### Fixed

- Increased default command timeout to 15 seconds ([#776](https://github.com/smartrent/grizzly/pull/776))
- Unsolicited server ACKs all messages ([#778](https://github.com/smartrent/grizzly/pull/778))
- Made `opts` arg optional in `Grizzly.Network.node_neighbor_update_request/2` ([#780](https://github.com/smartrent/grizzly/pull/780))

## [v6.7.0] - 2023-06-02

### Added

- Subscribe to all commands from a given node

### Fixed

- Replace `Logger.warn` with `Logger.warning`
- Ignore trailing bytes in `MultilevelSwitchReport`
- Transmission stats use minimum of `rssi_hops` for `rssi_dbm` instead of average
- Use signed values for Thermostat Setpoint Set (fixes an error when the value is negative)

### Misc

- Drop support for OTP 24

## [v6.6.1] - 2023-05-12

### Added

- Opt-in IEx autocompletion for `Grizzly.send_command` ([#763](https://github.com/smartrent/grizzly/pull/763))

### Fixed

- Ignore unexpected trailing bytes in ConfigurationReport ([#764](https://github.com/smartrent/grizzly/pull/764))
- Reduce log level for closed connections in UnsolicitedServer ([#765](https://github.com/smartrent/grizzly/pull/765))
- Better logging for DTLS unexpected error messages ([#767](https://github.com/smartrent/grizzly/pull/767))

## [v6.6.0] - 2023-05-05

### Changed / Fixed

- **Commands are no longer retried by default** ([#761](https://github.com/smartrent/grizzly/pull/761))
- Node Add Status always includes the `:command_classes` param even when empty ([#760](https://github.com/smartrent/grizzly/pull/760))

## [v6.5.1] - 2023-05-01

### Fixed

- Device classes in Node Add Status are now decoded like in Node Info Cached Get ([#759](https://github.com/smartrent/grizzly/pull/759))

## [v6.5.0] - 2023-05-01

### Added

- Implement Network Management Basic Node / Node Information Send command ([#749](https://github.com/smartrent/grizzly/pull/749))
- Add helper functions for some common debugging tasks ([#754](https://github.com/smartrent/grizzly/pull/754))
- Extract Home ID and network keys from Z/IP Gateway logs ([#755](https://github.com/smartrent/grizzly/pull/755))

### Changed / Fixed

- Reset tun/tap interface in Z/IP Gateway tunnel script ([#750](https://github.com/smartrent/grizzly/pull/750))
- Update RSSI to signal bar calculation ([#752](https://github.com/smartrent/grizzly/pull/752))
- Normalize multilevel switch report for Leviton DZ1KD-1BZ ([#753](https://github.com/smartrent/grizzly/pull/753))

## [v6.4.0] - 2023-04-18

### Added

- Support arbitrary extra items in Z/IP Gateway config ([#744](https://github.com/smartrent/grizzly/pull/744))
- Support signed integer, unsigned integer, enum, and bit field formats in Configuration Set ([#745](https://github.com/smartrent/grizzly/pull/745))

## [v6.3.0] - 2023-04-13

### Added

- Add API to restart Z/IP Gateway ([#739](https://github.com/smartrent/grizzly/pull/738))
- Implement S0/S2 Security Commands Supported Get/Report ([#739](https://github.com/smartrent/grizzly/pull/739))
- Implement Network Management Inclusion Failed Node Replace ([#741](https://github.com/smartrent/grizzly/pull/741))
- Optionally dump traces in Erlang external term format ([#742](https://github.com/smartrent/grizzly/pull/742))

### Changed/Fixed

- Allow all out-of-spec values in RSSI_REPORT ([#740](https://github.com/smartrent/grizzly/pull/740))
- Trace dumps are now formatted in the calling process instead of the trace server process ([#742](https://github.com/smartrent/grizzly/pull/742))

## [v6.2.0] - 2023-04-05

**NOTE**: Dropped support for Elixir 1.11.

### Added

- Add support for sending supervised commands ([#727](https://github.com/smartrent/grizzly/pull/727))

### Fixed

- Set more info flag when ACKing supervision get commands ([#735](https://github.com/smartrent/grizzly/pull/735))
- Fix trace dump for `:no_operation` commands ([#733](https://github.com/smartrent/grizzly/pull/733))

## [v6.1.1] - 2023-03-29

### Fixed

- Adds simple command name validation to Grizzly.Commands.Table to ensure correct naming in implementation modules
- Fixed the command class versions list for the HVAC virtual thermostat

## [v6.1.0] - 2023-03-22

### Added

- Network Management Inclusion CC ([#718](https://github.com/smartrent/grizzly/pull/718))
  - Neighbor Update Request
  - Neighbor Update Status
- Version CC ([#718](https://github.com/smartrent/grizzly/pull/718))
  - Capabilities Get
  - Capabilities Report
  - Z-Wave Software Get
  - Z-Wave Software Report

### Fixed

- Fix encoding of RSSI values in RSSI_REPORT ([#722](https://github.com/smartrent/grizzly/pull/722))
- Rescue errors in `Grizzly.Trace.dump/1` ([#723](https://github.com/smartrent/grizzly/pull/723))
- Fix command name for Wake Up Notification ([#725](https://github.com/smartrent/grizzly/pull/725))

## [v6.0.1] - 2023-03-13

### Fixed

- Typespec for `ThermostatSetpointReport` params now includes all params ([#712](https://github.com/smartrent/grizzly/pull/712))
- Enabled Dialyzer `:extra_return` and `:missing_return` options and fixed some incorrect return values ([#714](https://github.com/smartrent/grizzly/pull/714))
- Fixed interpretation of `:target_value` param in `SwitchMultilevel{Set,Report}` ([#715](https://github.com/smartrent/grizzly/pull/715))

## [v6.0.0] - 2022-03-03

### Fixed

- Handle illegal values from Z/IP Gateway in RSSI_REPORT ([#705](https://github.com/smartrent/grizzly/pull/705))

### BREAKING CHANGES

- Use abbreviations (`:f` and `:c`) for temperature scales ([#706](https://github.com/smartrent/grizzly/pull/706))

## [v5.4.1] - 2022-02-14

- Improve InclusionServer crash recovery from non-idle status ([#699](https://github.com/smartrent/grizzly/pull/699))

## [v5.4.0] - 2022-02-06

### Added

- Support for Master Code Set/Get/Report commands from User Codes command class ([#693](https://github.com/smartrent/grizzly/pull/693))

### Fixed

- Parse multilevel switch level 0xFF as 100 (instead of 99) ([695](https://github.com/smartrent/grizzly/pull/695))

## [v5.3.0] - 2022-12-16

### Added

- Support for getting configuration parameter name ([#691](https://github.com/smartrent/grizzly/pull/691))

## [v5.2.8] - 2022-12-09

### Changed

- Attempting to stop add/remove/learn mode while the inclusion server is idle returns `:ok` ([#688](https://github.com/smartrent/grizzly/pull/688))
- Types for command classes and device classes are now generated from their mapping tables ([#689](https://github.com/smartrent/grizzly/pull/689))

## [v5.2.7] - 2022-11-17

### Fixed

- Fix virtual temperature sensor command handling ([#685](https://github.com/smartrent/grizzly/pull/685))

## [v5.2.6] - 2022-10-28

### Fixed

- Format IPv6 addresses in traces using standard port notation ([#677](https://github.com/smartrent/grizzly/pull/677))
- Record correct node IP for outgoing traces ([#679](https://github.com/smartrent/grizzly/pull/679))
- Prevent a crash in `Grizzly.Trace.dump/1` when an S2 device has recently been included ([#680](https://github.com/smartrent/grizzly/pull/680))

## [v5.2.5] - 2022-10-18

### Fixed

- Support unknown weekday in clock command class (@jfcloutier)

## [v5.2.4] - 2022-10-14

### Added

- Implement event parameter decoding for home security idle notifications ([#671](https://github.com/smartrent/grizzly/pull/671))

## [v5.2.3] - 2022-09-28

### Fixed

- Fix Elixir 1.14 deprecation warnings (@bjyoungblood)

## [v5.2.2] - 2022-09-27

### Fixed

- Handling timeout of node removing (@jfcloutier)

## [v5.2.1] - 2022-09-26

### Fixed

- Fix typo for celsius (@jwdotjs)
- Handle timeout on DSK input during inclusion (@jfcloutier)
- Fix inclusion crash leading to invalid in-memory controller state

## [v5.2.0] - 2022-09-15

### Added

- `Grizzly.VirtualDevices.Device.set_device_id/2` callback function (@jfcloutier)
- `Grizzly.VirtualDevices.TemperatureSensor.state()` now has a `:device_id`
  field (@jfcloutier)
- `Grizzly.VirtualDevices.TemperatureSensor.set_device_id/2` implementation
  (@jfcloutier)
- `Grizzly.VirtualDevices.Thermostat.set_device_id/2` implementation (@jfcloutier)

### Fixed

- When a virtual device is started outside of Grizzly, Grizzly would still
  automatically add them to virtual network (@jfcloutier)

## [v5.1.2] - 2022-08-09

### Fixed

- Handling timeouts during S2 inclusion process

## [v5.1.1] - 2022-08-09

### Fixed

- GenServer calling its self during S2 inclusion

## [v5.1.0] - 2022-08-02

### Changed

- Deprecated `Grizzly.Inclusions.stop/0`, please use `remove_node_stop/0`,
  `add_node_stop/0`, or `learn_mode_stop/0` instead.

### Added

- `Grizzly.Inclusions.NetworkAdapter` behaviour
- `Grizzly.Inclusions.ZWaveAdapter` implementation of the network adapter
  behaviour (default adapter Grizzly uses).

### Fixed

- Issues around canceling the inclusion process

## [v5.0.2] - 2022-07-28

## Fixed

- Passing a configuration set `value` parameter that is bigger than the supplied
  `size` parameter. (@jfcloutier)

## [v5.0.1] - 2022-06-27

### Fixed

- Virtual thermostat reporting fan state command class did not actually support
  that command class (@jfcloutier)

## [v5.0.0] - 2022-06-24

Refactored the `Grizzly.VirtualDevices.Device` behaviour. The behavior no longer
has an `init/1` callback. Moreover, the `handle_command/2` callback still exists
but second parameter is not `Grizzly.VirtualDevices.Device.device_opts()` type.
Lastly, a new callback `device_spec/1` was added.

The change to `handle_command/2` also changes the return value expected by the
behaviour. If you have implemented this behaviour see the documentation for
`Grizzly.VirtualDevices.Device.handle_command/2` for new return values.

The `Grizzly.VirtualDevices.Thermostat` and
`Grizzly.VirtualDevices.TemperatureSensor` have both been updated to reflect the
changes to the virtual device behaviour. In order to use either of these virtual
devices you will need to call `start_link/1` on them before you're able to send
commands to them.

This change requires process based device implementations to be supervised
outside of the Grizzly supervision tree. This allows the consuming application
the ability to control how the virtual devices are started and when and how they
should be shut down.

### Changed

- Deleted `Grizzly.VirtualDevices.init/1` callback
- Changed parameters and return values from
  `Grizzly.VirtualDevices.Device.handle_command/2`
- Deleted `Grizzly.VirtualDevices.handle_info/2` callback
- `Grizzly.VirtualDevices.Thermostat` (see module docs)
- `Grizzly.VirtualDevices.TemperatureSensor` (see module docs)

### Added

- `Grizzly.VirtualDevices.Device.device_opts()` type
- `Grizzly.VirtualDevices.Device.device_spec/1` callback
- Support for empty alarm report event params (@jfcloutier)
- Support long range node ids in the smart start meta extension field
  `:network_status` (@jfcloutier)
- `Grizzly.VirtualDevices.whereis/1`

### Fixed

- `Grizzly.ZWave.Commands.NodeAddStatus.param()` value `:node_id` type now
  reflects virtual device ids

## [v4.0.1] - 2022-06-13

### Fixed

- Fix ClockReport command `:name` field (@jfcloutier)
- Fix forcing `zipgateway` cache update when calling `Grizzly.Node.get_info/2`

## [v4.0.0] - 2022-05-19

Breaking change in the `Grizzly.VirtualDevices.Device` behaviour. If you have
not implemented a custom virtual device then you can safely upgrade.

If you have implemented a custom virtual device the `init/0` callback is now
`init/1`. To upgrade change your implementation to:

```elixir
@impl Grizzly.VirtualDevice.Device
def init(_) do
  {:ok, my_state, my_device_class}
end
```

The change is to add the `_` as the argument to your `init` implementation.

### Changed

- `Grizzly.VirtualDevice.Devices` behaviour `init/0` callback is now `init/1`

### Added

- Support for the sensor multilevel get command for the
  `Grizzly.VirtualDevices.Thermostat` virtual device implementation
- Virtual device support for `Grizzly.Node.set_lifeline_association/2`
- Add virtual device support for the battery get command
- Add virtual device support for the version get command
- Add `handle_info/2` callback in `Grizzly.VirtualDevices.Device` behaviour to
  allow asynchronous events to broadcast Z-Wave reports
- Add return value for `handle_command/2` callback in
  `Grizzly.VirtualDevices.Device` behaviour to allow broadcasts Z-Wave reports
  based off incoming commands
- `Grizzly.VirtualDevices.add_device/2` now allows a tuple
  `{my_device_impl, my_device_opts}` has the first argument
- `Grizzly.VirtualDevices.TemperatureSensor` virtual device

### Fixed

- Ensure `Grizzly.VirtualDevices.Thermostat` device implementation returns
  `:noreply` for unsupported command classes. (@jfcloutier)
- Fix to calculating RSSI averages (@jfcloutier)
- Crashing the initialization of a new virtual device caused the virtual device
  network to get in a bad state

## [v3.0.0] - 2022-05-12

Breaking change in these modules:

- `Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance`
- `Grizzly.ZWave.Commands.PriorityRouteReport`

In `NetworkManagementInstallationMaintenance` command class the `:speed` type
is now a list of `speed()` rather than a single speed. This effects the command
`PriorityRouteReport` parameter `:speed`. This parameter is now a list of
`speed()` rather than a single value.

If you do not use this command you can safely upgrade with no changes.

If you do use this command you will need to update code that assumes the
`:speed` parameter is single value.

This change was made to better aline with the Z-Wave specification.

### Changed

- `Grizzly.ZWave.CommandClasses.NetworkManagementInstallationMaintenance.neighbor_param()`
  type's `:speed` param returns a list of type `speed()`. (@jfcloutier)
- `Grizzly.ZWave.Commands.PriorityRouteReport.params()`'s `:speed` param is now
  a list of `speed()` than than a single `speed()`. (@jfcloutier)

### Added

- `Grizzly.VirtualDevices` module to allow virtual devices
- `Grizzly.VirtualDevices.Device` behaviour to allow custom virtual devices to
  be used with Grizzly
- `Grizzly.VirtualDevices.Thermostat` virtual device implementation for a basic
  virtual thermostat device
- `Grizzly.ZWave.DeviceClass` module for defining common device class
  specifications
- `Grizzly.send_command/4` virtual device support, so you can send commands to
  virtual devices just like you would a regular Z-Wave device
- `Grizzly.Network.opt()` type now allows for a `:seq_number` option
- `Grizzly.Network.get_all_node_ids/1` to get a list of both regular and virtual
  device ids
- `Grizzly.Node.get_info/2` support for virtual device

### Fixed

- Error when the primary route report would try to be handled (@jfcloutier)

## [v2.1.0] - 2022-04-27

### Added

- `Grizzly.ZWave.CommandClasses.WindowCovering` (@jfcloutier)
- `Grizzly.ZWave.Commands.WindowCoveringGet` (@jfcloutier)
- `Grizzly.ZWave.Commands.WindowCoveringReport` (@jfcloutier)
- `Grizzly.ZWave.Commands.WindowCoveringSet` (@jfcloutier)
- `Grizzly.ZWave.Commands.WindowCoveringStartLevelChange` (@jfcloutier)
- `Grizzly.ZWave.Commands.WindowCoveringStopLevelChange` (@jfcloutier)
- `Grizzly.ZWave.Commands.WindowCoveringSupportedGet` (@jfcloutier)
- `Grizzly.ZWave.Commands.WindowCoveringSupportedReport` (@jfcloutier)

### Fixed

- When a lock does not encode an `UserCodeReport` as an event parameter (@jfcloutier)
- When an unknown user code is encoded as a empty string (@jfcloutier)

## [v2.0.0] - 2022-03-21

### Breaking change

For this release we removed the `on_ready` option for Grizzly and added the
`Grizzly.StatusReporter` behaviour. This is a module that the consuming
application can implement to get a more specific type of ready status. There are
a handful of moving parts to getting Z-Wave and Grizzly up, so this behaviour
can be extended over time to handle more ready cases.

To use the status reporter:

```elixir
defmodule MyApp.StatusReporter do
  @behaviour Grizzly.StatusReporter

  @impl Grizzly.StatusReporter
  def read() do
    # Grizzly and Z-Wave are set up!
    :ok
  end

  @impl Grizzly.StatusReporter
  def zwave_firmware_update_status(status) do
    # Grizzly is trying informing you if it tried to update teh Z-Wave firmware
    # and what the status of that attempt is
    :ok
  end
end
```

### New feature

The newest feature is automatic Z-Wave firmware update. This feature is opt-in
and will only try to run if configured. This is useful if you need to update
the Z-Wave firmware when Grizzly starts. Here's the configuration:

```elixir
grizzly_opts = [
  # enables the updating the Z-Wave chip
  update_zwave_firmware: true,
  # configure which firmwares you might want to flash to the Z-Wave chip.
  zwave_firmware: [%{chip_type: 7, path: "/path/to/firmware_file", version: "7.16.03"}],
  # path the Z-Wave programmer program provided by Silicon Labs
  zw_programmer_path: "/usr/sbin/zw_programmer",
  # ..other options
]

{Grizzly, grizzly_opts}
```

### Changed

- removed `:on_ready` Grizzly option

### Added

- Z-Wave firmware updates on Grizzly start (@jfcloutier)
- Ability to get the Z-Wave chip version information (@jfcloutier)
- Add `Grizzly.StatusReporter` behaviour

## [v1.0.1] - 2022-02-28

### Fixed

- Ignore extra bytes reported in association group list by some devices (@jfcloutier)
- Decode `0x00..0x063` as `:on` in Basic command class to align with Z-Wave
  specification (@jfcloutier)

## [v1.0.0] - 2021-12-20

This release bumps Grizzly to v1.0.0. Grizzly has been used for many years now
and has helped a product pass Z-Wave certification. Most the work that gone
into Grizzly for the last little while has been minor changes and bug fixes, but
core API has remained stable.

Thank you to everyone who has contributed over the years!

## [v0.22.7] - 2021-12-2

### Fixed

- Unhandled errors when trying to firmware upgrade (@jfcloutier)
- Unhandled errors when trying to get failed node list (@jfcloutier)

## [v0.22.6] - 2021-11-29

### Added

- `Grizzly.ZWave.CommandClasses.BarrierOperator` (@jfcloutier)
- `Grizzly.ZWave.Commands.BarrierOperatorGet` (@jfcloutier)
- `Grizzly.ZWave.Commands.BarrierOperatorReport` (@jfcloutier)
- `Grizzly.ZWave.Commands.BarrierOperatorSet` (@jfcloutier)
- `Grizzly.ZWave.Commands.BarrierOperatorSignalGet` (@jfcloutier)
- `Grizzly.ZWave.Commands.BarrierOperatorSignalReport` (@jfcloutier)
- `Grizzly.ZWave.Commands.BarrierOperatorSignalSet` (@jfcloutier)
- `Grizzly.ZWave.Commands.BarrierOperatorSignalSupportedGet` (@jfcloutier)
- `Grizzly.ZWave.Commands.BarrierOperatorSignalSupportedReport` (@jfcloutier)

## [v0.22.5] - 2021-11-22

### Added

- `Grizzly.ZWave.Commands.FailedNodeListGet` (@jfcloutier)
- `Grizzly.Network.report_failed_node_ids/0` (@jfcloutier)

## [v0.22.4] - 2021-11-16

### Added

- `Grizzly.ZWave.Commands.ThermostatSetpointSupportedGet` (@bjyoungblood)
- `Grizzly.ZWave.Commands.ThermostatSetpointSupportedReport` (@bjyoungblood)
- `Grizzly.ZWave.Commands.ThermostatModeSupportedGet` (@bjyoungblood)
- `Grizzly.ZWave.Commands.ThermostatModeSupportedReport` (@bjyoungblood)
- Add how to heal Z-Wave network to cookbook

### Fixes

- No longer hard crashes on Z/IP Packets that don't follow Z-Wave spec
- Fix crash when zipgateway's mailbox queue is full when trying to send command
  to a sleeping device

## [v0.22.3] - 2021-10-22

### Fixes

- Make CentralSceneSupportedReport more forgiving

## [v0.22.2] - 2021-10-12

### Fixes

- Incorrect parsing of `:motion` type from a SensorBinaryReport

## [v0.22.1] - 2021-10-4

### Added

- Support version 3 `Grizzly.ZWave.Commands.S2ResynchronizationEvent` command
  (Z-Wave LR)

### Fixes

- `Grizzly.ZWave.Commands.FailedNodeListReport` command not able to parse empty
  extended node id list

## [v0.22.0] - 2021-10-01

This release brings Grizzly up to speed to support command classes that have
been updated to support extended node ids. This allows Grizzly to support
zipgateway versions that have Z-Wave Long Range support. That is zipgateway
`>= v7.15`.

## Changed

- Removed `Grizzly.ZWave.Commands.NodeAddStatus.status()` type
  - Now is `Grizzly.ZWave.CommandClasses.NetworkManagementInclusion.node_add_status()`
- Changed return type of
  `Grizzly.ZWave.CommandClasses.ThermostatSetpoint.decode_type/1` function from
  `{:ok, Grizzly.ZWave.CommandClasses.ThermostatSetpoint.type()}` to
  `Grizzly.ZWave.CommandClasses.ThermostatSetpoint.type()`

### Added

- Support version 4 `Grizzly.ZWave.Commands.NodeListReport` command (Z-Wave LR)
- Support version 4 `Grizzly.ZWave.Commands.NodeRemoveStatus` command (Z-Wave LR)
- Support version 4 `Grizzly.ZWave.Commands.FailedNodeListReport` command (Z-Wave LR)
- Support version 4 `Grizzly.ZWave.Commands.FailedNodeRemove` command (Z-Wave LR)
- Support version 4 `Grizzly.ZWave.Commands.FailedNodeRemoveStatus` command (Z-Wave LR)
- Support version 4 `Grizzly.ZWave.Commands.NodeInfoCachedGet` command (Z-Wave LR)
- Support version 4 `Grizzly.ZWave.Commands.RssiReport` command (Z-Wave LR)
- `Grizzly.ZWave.Commands.ZWaveLongRangeChannelGet` command
- `Grizzly.ZWave.Commands.ZWaveLongRangeChannelReport` command
- `Grizzly.ZWave.Commands.ZWaveLongRangeChannelSet` command
- `Grizzly.ZWave.Commands.ExtendedNodeAddStatus` command
- `Grizzly.ZWave.Commands.NetworkManagementMultiChannelEndPointGet` command
- `Grizzly.ZWave.Commands.NetworkManagementMultiChannelEndPointReport` command
- `Grizzly.ZWave.Commands.NetworkManagementMultiChannelCapabilityGet` command
- `Grizzly.ZWave.Commands.NetworkManagementMultiChannelCapabilityReport` command
- `Grizzly.Network.add_long_range_device/2` function
- `Grizzly.ZWave.CommandClasses.NetworkManagementInclusion.parse_node_add_status/1`
  function
- `Grizzly.ZWave.CommandClasses.NetworkManagementInclusion.parse_node_info/1`
  function
- `Grizzly.ZWave.CommandClasses.NetworkManagementInclusion.node_add_status()` type
- `Grizzly.ZWave.CommandClasses.NetworkManagementInclusion.extended_node_info_report()`
  type
- `Grizzly.ZWave.CommandClasses.NetworkManagementInclusion.node_info_report()` type
- `Grizzly.ZWave.CommandClasses.NetworkManagementInclusion.tagged_command_classes()`
  type
- `Grizzly.ZWave.Command.encode_params/2` optional callback
- Support parsing header new IME report stats from version 5 of ZIP command class
- The atom `:na` to `Grizzly.ZWave.CommandClasses.ThermostatSetpoint.type()` type

### Fixed

- Parsing thermostat setpoint types that are considered NA by the specification
- Version report command parsing for zipgateway >= 7.14

## [v0.21.1] - 2021-9-21

### Fixed

- Transmission stats
  - Ensure `:rssi_4bars` and `:rssi_dbm` accurately calculate no signal when `:rssi_hops` are nil

## [v0.21.0] - 2021-9-20

### Added

- Transmission stats
  - Added `:rssi_4bars` and `:rssi_dbm`

### Changed

- Transmission stats
  - `:rssi` is now `:rssi_hops` and has been changed from a tuple to a list
  - `:last_working_route` and `:transmission_speed` have been separated
  - `:last_working_route` is now a list
  - `:route_changed` is now a boolean

### Fixed

- Fix error when sending `Grizzly.ZWave.Commands.StatisticsGet`

## [v0.20.2] - 2021-8-11

### Changed

- Turn off TLS warning for connecting with `zipgateway` server

## [v0.20.1] - 2021-7-1

### Added

- Support for ScheduleEntryLock command class
  - `Grizzly.ZWave.CommandClasses.ScheduleEntryLock`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingGet`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingReport`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockDailyRepeatingSet`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockEnableAllSet`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockEnableSet`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetGet`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetReport`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockTimeOffsetSet`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockWeekDayGet`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockWeekDayReport`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockWeekDaySet`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockYearDayGet`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockYearDayReport`
  - `Grizzly.ZWave.Commands.ScheduleEntryLockYearDaySet`
  - `Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedGet`
  - `Grizzly.ZWave.Commands.ScheduleEntryTypeSupportedReport`
- Support for elixir 1.12-otp-24

Thank you to those who contributed to this release:

- Grace Yanagida

### Fixed

- Invalid warnings when calling function in `Grizzly.SwitchBinary`

## [v0.20.0] - 2021-6-14

The release breaks the return value of
`Grizzly.ZWave.CommandClasses.NodeProvisioning.optional_dsk_to_binary/1` from
returning `nil` to returning a DSK filled will `0`s if an empty binary string
is passed into the function.

If you have not called this function directly then it is safe to upgrade to
`v0.20.0`.

### Changed

- Allow values greater than `99` to be passed in
  `Grizzly.ZWave.Commands.SwitchMultilevelSet.encode_target_value/1`

## [v0.19.1] - 2021-4-23

### Added

- Configuration option for setting the RF region
- Configuration option for setting power level settings
- Allow passing send command options to functions in `Grizzly.SwitchBinary`
  module

Thank you to djantea for testing out the RF configuration changes!

## [v0.19.0] - 2021-4-19

Breaking change in regards to how meta extensions are passed to
`Grizzly.Network.set_node_provisioning/3`.

The meta extension were once structs that need to be built and passed to the
function, but now they are a keyword list. Please see
`Grizzly.ZWave.SmartStart.MetaExtension` module for more details on the keyword
keys and their values.

## Added

- Added `Grizzly.SwitchBinary` has a higher level helper module to control
- binary switches
- Added basic support for including Z-Wave LR devices
- Added LR command class support for NetworkManagementInclusion
- Support version 2 of User Number Report command
- Better handling of RSSI channel reports
- Better handling of Association Group Name Report command

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.18.3] - 2021-3-11

### Added

- `Grizzly.ZWave.DSK.parse_pin/1`
- `Grizzly.ZWave.DSK.to_pin_string/1`

### Fixed

- Ensure that the DSK binary is 128 bits

## [v0.18.2] - 2021-2-18

### Added

- Use [cerlc](https://github.com/mdsebald/cerlc) library for `Grizzly.ZWave.CRC`
- Clean up inspects from tests
- Ensure `zipgateway` files are usable by system utils for `zipgateway`

## [v0.18.1] - 2021-2-10

### Fixed

- Fix up dialyzer types

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.18.0] - 2021-2-10

This release breaks the DSK API and other supporting APIs. If you have not
supported S2 inclusions, smart start, or use the DSK API for any reason then it
should be safe to upgrade.

The break to DSKs is the new `Grizzly.ZWave.DSK.t()` struct. All inclusion and
node provisioning commands now expect a `Grizzly.ZWave.DSK.t()`. There are two
times you will need to get a `DSK.t()`:

1. User input of a DSK pin (the nicely formatted representation)
1. The binary (`<<>>`) representation.

For the first case you can use `Grizzly.ZWave.DSK.parse/1` and for the second
case you can use `Grizzly.ZWave.DSK.new/1`.

A common use case for DSKs is using the DSK pin (the first 5 digits in the DSK)
to do S2 inclusion. This was done by calling
`Grizzly.Inclusions.set_input_dsk/1`. Where the input DSK was an
`non_neg_integer()`. This API has been changed to take a `DSK.t()`.

### Example

```elixir
dsk_pin = "12345"
{:ok, dsk} = Grizzly.ZWave.DSK.parse(dsk_pin)

Grizzly.Inclusions.set_input_dsk(dsk)
```

This API is more useful for taking user input (which the DSK pin is), parsing
it, and passing the DSK to the inclusion process. Also this pushes validation of
DSK to the `Grizzly.ZWave.DSK.parse/1` function.

```elixir
dsk_pin = "123456"
{:error, :invalid_dsk} = Grizzly.ZWave.DSK.parse(dsk_pin)
```

The `DSK.t()` has the `String.Chars` protocol implemented so if you want to a
pretty representation of the DSK, say for logging or displaying the DSK to the
user, you call the `to_string/1` function on the `DSK.t()`. Also, see
`Grizzly.ZWave.DSK.to_string/2` for more details.

If you need to access the raw binary form of the DSK you the `DSK.t()` exposes
the `:raw` field, so you can access that via `dsk.raw`.

This release also added support S2/SmartStart QR code generation. See the
`Grizzly.ZWave.QRCode` module for more details.

### Changed

- `Grizzly.Inclusions.set_input_dsk/1` use to take `non_neg_integer()` type as
- an argument, but the type has changed to `Grizzly.ZWave.DSK.t()`
- `Grizzly.ZWave.CommandClasses.NodeProvisioning.optional_dsk_to_binary/1` use
  to take a string as the DSK input but now it takes `Grizzly.ZWave.DSK.t()`
- `Grizzly.ZWave.CommandClasses.NodeProvisioning.optional_binary_to_dsk/1` use
  to take a string as the DSK input but now it takes `Grizzly.ZWave.DSK.t()`
- The following commands had params that took a string for the DSK and now take
  `Grizzly.ZWave.DSK.t()`:
  - `Grizzly.ZWave.Commands.DSKReport`
  - `Grizzly.ZWave.Commands.LearnModeSetStatus`
  - `Grizzly.ZWave.Commands.NodeAddDSKReport`
  - `Grizzly.ZWave.Commands.NodeAddDSKSet`
  - `Grizzly.ZWave.Commands.NodeAddStatus`
  - `Grizzly.ZWave.Commands.NodeProvisioningDelete`
  - `Grizzly.ZWave.Commands.NodeProvisioningGet`
  - `Grizzly.ZWave.Commands.NodeProvisioningListIterationReport`
  - `Grizzly.ZWave.Commands.NodeProvisioningReport`
  - `Grizzly.ZWave.Commands.NodeProvisioningSet`
  - `Grizzly.ZWave.Commands.SmartStartJoinStarted`

### Added

- QR code support via the `Grizzly.ZWave.QRCode` module.

## [v0.17.7] - 2021-2-4

### Fixed

- An issue when `zipgateway` sends an invalid `FirmwareMDReport` packet causing
  invalid hardware version errors during firmware updates.

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.17.6] - 2021-2-3

### Fixed

- Grizzly would throw an exception when calling
  `Grizzly.commands_for_command_class/1`
- Grizzly would always return an empty list of supported commands for a command
  class when calling `Grizzly.commands_for_command_class/1` even though Grizzly
  supports commands for that command class
- Fix S2 DSK pin setting when the pin was <256

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.17.5] - 2021-1-26

### Added

- Docs on operating indicator light

### Fixed

- Crash when indicator handler is `nil`
- Math for `MeterReport`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.17.4] - 2021-1-21

### Added

- Support for handling indicator events via the `:indicator_handler` option to
  the `Grizzly.Supervisor`.

## [v0.17.3] - 2021-1-14

### Added

- `Grizzly.Trace` module for logging Z/IP packets that are sent from and
  received by Grizzly.

### Fixed

- No match error when trying to encode a node id list

## [v0.17.2] - 2021-1-13

### Added

- Decoding the `NodeInfoCacheGet` command

### Fixed

- Incorrect return value for `NodeInfoCacheGet` when decoding the params
- Issues around firmware updates and `zipgateway` versions >= 7.14.2

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.17.1] - 2021-1-12

Added supported for using `zipgateway` versions >= 7.14.2.

When upgrading from a `zipgateway` version less than 7.14.2 you should provide
the `zgw_eeprom_to_sqlite` utility in your system or firmware. The utility should
be located in `/usr/bin`. Grizzly will try to run the utility if we detected it.

You can configure the database file and eeprom file via `:database_file` and
`:eeprom_file` options for the `Grizzly.Supervisor`. These are optional and no
changes are necessary for how you start Grizzly if you have already been using
Grizzly.

### Added

- Support for `zipgateway` versions >= 7.14.2
- `:eeprom_file` to supervisor args (optional)
- `:database_file` to supervisor args (optional)

Thank you to those who contributed to this release:

- Frank Hunleth

## [v0.17.0] - 2021-1-8

Breaking change with how Grizzly reports water alarms.

If you are listening for water alarm notifications you will need to update from
`:water` to `:water_alarm`. This change was made to align better with the Z-Wave
specification.

### Added

- Complete support for all notification events
- Support for version 2 of the Antitheft command class
- Support for SceneActuatorConf command class
- Support for SceneActivation command class
- More support for Erlang 23.2 DSL messages

### Changed

- `:water` is not `:water_alarm` notification

### Fixed

- When receiving the supervision command class with a command encapsulated
  Grizzly was not actually processing the encapsulated command.

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.16.2] - 2020-12-23

### Added

- `:list_mode` param for the
  `Grizzly.ZWave.Commands.AssociationGroupInfoReport` command.

## [v0.16.1] - 2020-12-22

### Added

- `Grizzly.ZWave.Commands.S2ResynchronizationEvent`

### Fixed

- Data structure change in the associations file when deleting all associations
- Wrong `MultiChannelAssociation` version number being reported to devices
- Ensure ack responses are sent when extra commands are received
- Force bind to `fd00::aaaa::2` since `zipgateway` forces that all acks come
  from this address
- Crash when receiving errors other than timeouts when trying to establish
  connections to `zipgateway`

Thank you to those who contributed to this release:

- Frank Hunleth

## [v0.16.0] - 2020-12-21

This release introduces a breaking change to the naming of the command class get
and command class report modules. If you are using those modules directly, you
will need to update to the use the new module names.

### Changed

- `Grizzly.ZWave.Commands.CommandClassGet` is now
  `Grizzly.ZWave.Commands.VersionCommandClassGet`
- The `:name` field for `:command_class_get` is now `:version_command_class_get`
- `Grizzly.ZWave.Commands.CommandClassReport` is now
  `Grizzly.ZWave.Commands.VersionCommandClassReport`
- The `:name` field for `:command_class_report` is now
  `:version_command_class_report`
- Easier to read stack traces when some GenServers crash

### Added

- Added support for forcing the Z-Wave cache to update when fetching node
  information. See `Grizzly.Node.get_info/2` for more information.
- Support for OTP 23.2

### Fixed

- In some GenServers an exception would cascade

## [v0.15.11] - 2020-12-11

### Added

- Support for DoorLock command class version 4

### Fixed

- Querying command class versions for extra commands on the LAN will return the
  version report correctly now.

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.15.10] - 2020-12-8

### Added

- Support for querying the gateway about the command class versions it supports
  when querying extra supported command classes.

### Fixed

- Spelling error fix for the `WakeUpNoMoreInformation` command name

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.15.9] - 2020-12-4

### Added

- Sending commands directly to the Z-Wave Gateway by passing
  `Grizzly.send_command/4` `:gateway` as the node id.
- How to get DSK for a device in the cookbook docs

### Fixed

- Spelling, whitespace and markdown issues in docs

Thank you to those who contributed to this release:

- Frank Hunleth

## [v0.15.8] - 2020-12-1

### Added

- Support for `ZwavePlusInfo` command class

### Fixed

- No function clause matching error when a connection closes
- Missing support for `:undefined` indicator

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.15.7] - 2020-11-30

### Added

- Add `Grizzly.send_binary/2`

### Fixed

- Error when handling older Z-Wave devices that use CRC16 checksums over any
  security schema
- Internal typo

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.15.6] - 2020-11-19

### Added

- Add support for `NetworkUpdateRequest` command
- Add `Grizzly.Network.request_network_update/0`

### Changed

- Drop support for Elixir 1.8 and 1.9

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.15.5] - 2020-11-12

### Added

- Support multi-channel associations in the unsolicited destination

### Fixed

- Add the `:aggregated_endpoints` params to the `MultiChannelEndpointReport`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.15.4] - 2020-11-5

### Added

- Network management installation and maintenance command class
- Clock command class
- Unsolicited server support for the extra command classes:
  - Association group command class list
  - Association group name get
  - Association group info get
  - Device reset locally notification

### Changed

- When a supervision get command is received in the unsolicited destination we
  send the supervision report for that command back to the sender.
- Dev deps updates
- Code clean up

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.15.3] - 2020-10-27

### Fixed

- Documentation fixes
- Internal firmware update runner bug

### Changed

- Updates in internal association persistence

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.15.2] - 2020-10-23

### Added

- Support for the `unknown_event` notification event for the `access_control`
  notification type

### Fixed

- Support `SupervisionGet` command for notifications.
- Tried to send `:ack_response` via unsolicited server which the unsolicited
  server should not be sending anything directly.
- Fix typo in code

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.15.1] - 2020-10-09

### Added

- Support for getting association grouping report via the Z-Wave PAN
- Support for setting associations via the Z-Wave PAN
- Support for removing associations via the Z-Wave PAN
- Support for getting specific associations via the Z-Wave PAN
- Added option to `Grizzly.Supervisor` for where to store data used by the
- unsolicited server for support of extra command classes

### Changed

- When getting the associations via the Z-Wave PAN, Grizzly will now look at the
  stored data and respond accordingly.

### Fixed

- `Grizzly.ZWave.Commands.SwitchBinaryReport` did not properly encode and decode
  the version 2 of the switch binary command class

## [v0.15.0] - 2020-10-08

This release does a major overhaul on the `Grizzly.Transport` behaviour. If you
haven't implemented a custom transport this release should not effect you and
you should be able to update with out too many issues, see the "Removed" section
of this release to note any other breaking changes. If you have created a
custom transport please see the documentation for `Grizzly.Transport` to see how
transports are now implemented.

### Added

- How to resetting the controller to the cook book
- The `:unsolicited_destination` option to the `Grizzly.Supervisor`
- Support for the association get command via the Z-Wave PAN network
- Support proper ack response when a command is delivered through the Z-Wave
  PAN
- `Grizzly.Transports.UDP` - This is experimental and is subject to change.
- `Grizzly.ZWave.CommandClasses.CRC16Encap`
- `Grizzly.ZWave.Commands.CRC16Encap`
- `Grizzly.ZWave.CommandClasses.Powerlevel`
- `Grizzly.ZWave.Commands.PowerlevelGet`
- `Grizzly.ZWave.Commands.PowerlevelReport`
- `Grizzly.ZWave.Commands.PowerlevelSet`
- `Grizzly.ZWave.Commands.PowerlevelTestNodeGet`
- `Grizzly.ZWave.Commands.PowerlevelTestNodeReport`
- `Grizzly.ZWave.Commands.PowerlevelTestNodeSet`

### Changed

- Refactored the `Grizzly.Transport` behaviour - please see documentation to see
  how to use the behaviour now.

### Removed

- `Grizzly.Node.get_node_info/1`

### Fixed

- `MultiChannelAssociationGet` command name fix
- Documentation
- Command class fixes for the `Grizzly.ZWave.CommandClasses.Time`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier
- Jon Wood

## [v0.14.8] - 2020-09-29

### Added

- Support for power management notifications

## [v0.14.7] - 2020-09-25

### Added

- Added `Grizzly.ZWave.Commands.FailedNodeListReport` command

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.14.6] - 2020-09-18

### Added

- Cookbook documentation for common uses of Grizzly

### Changed

- Reduced the amount of logging

## [v0.14.5] - 2020-09-02

### Fixed

- Commands with aggregated reports did not aggregate the results as expected
- Commands with aggregated reports would crash if that device was also
  handling another command due to the aggregate handler assuming that only one
  command was being processed at one time

## [v0.14.4] - 2020-09-01

### Added

- Full support for `ThermostatFanMode` mode types

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## [v0.14.3] - 2020-08-31

### Fixed

- Fix the start order of the connection supervisor and Z-Wave ready checker
  to ensure the supervisor process is alive before trying to test the
  connection

## v0.14.2

Added

- `Grizzly.ZWave.CRC` module for CRC functions related to the Z-Wave protocol

Removed

- `crc` dependency

## v0.14.1

Enhancements

- Support `zipgateway` 7.14.01
- Add `Grizzly.ZWave.CommandClasses.CentralScene`
- Add `Grizzly.ZWave.Commands.CentralSceneConfigurationGet`
- Add `Grizzly.ZWave.Commands.CentralSceneConfigurationSet`
- Add `Grizzly.ZWave.Commands.CentralSceneConfigurationReport`
- Add `Grizzly.ZWave.Commands.CentralSceneNotification`
- Add `Grizzly.ZWave.Commands.CentralSceneSupportedGet`
- Add `Grizzly.ZWave.Commands.CentralSceneSupportedReport`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.14.0

This breaking change has to do with how Grizzly is started. It is no longer an
application. Grizzly exposes the `Grizzly.Supervisor` module for a consuming
application to add to its supervision tree. All other APIs are backwards capable.

See the [upgrade guide](https://gist.github.com/mattludwigs/bb312906b1bf85a021080c45d1562f2b)
for more specifics on how to upgrade.

Breaking Changes

- Grizzly is not an OTP application anymore and will need to be started
  manually via the new `Grizzly.Supervisor` module
- All application config/mix config options are not used
- Removed the `Grizzly.Runtime` module

Enhancements

- Add `Grizzly.Supervisor` module
- Add `Grizzly.ZWave.CommandClasses.Indicator`
- Add `Grizzly.ZWave.Commands.IndicatorGet`
- Add `Grizzly.ZWave.Commands.IndicatorSet`
- Add `Grizzly.ZWave.Commands.IndicatorReport`
- Add `Grizzly.ZWave.Commands.IndicatorSupportedGet`
- Add `Grizzly.ZWave.Commands.IndicatorSupportedReport`
- Add `Grizzly.ZWave.CommandClasses.Antitheft`
- Add `Grizzly.ZWave.Commands.AntitheftGet`
- Add `Grizzly.ZWave.Commands.AntitheftReport`
- Add `Grizzly.ZWave.CommandClasses.AntitheftUnlock`
- Add `Grizzly.ZWave.Commands.AntitheftUnlockSet`
- Add `Grizzly.ZWave.Commands.AntitheftUnlockGet`
- Add `Grizzly.ZWave.Commands.AntitheftUnlockReport`
- Add `Grizzly.ZWave.Commands.ConfigurationBulkGet`
- Add `Grizzly.ZWave.Commands.ConfigurationBulkSet`
- Add `Grizzly.ZWave.Commands.ConfigurationBulkReport`
- Add `Grizzly.ZWave.Commands.ConfigurationPropertiesGet`
- Add `Grizzly.ZWave.CommandClasses.ApplicationStatus`
- Add `Grizzly.ZWave.Commands.ApplicationBusy`
- Add `Grizzly.ZWave.Commands.ApplicationRejectedRequest`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.13.0

This update breaks the main `Grizzly.send_command/4` API as Grizzly use to
respond with different tuples but now it will return with the new
`Grizzly.Report.t()` data structure. A full guide on the breaking changes
and what needs to be updated can be found [here](https://gist.github.com/mattludwigs/323cbdbfc32075745cd3fdae7163c930).

This change allows us to gather more information about a response from Grizzly.
For example, with this change you can get transmission stats about network
properties when sending a command now:

```elixir
{:ok, report} = Grizzly.send_command(node_id, command, command_args, transmission_stats: true)

report.transmission_stats
```

See the `Grizzly.Report` module for full details.

Enhancements

- Add `Grizzly.Report`
- Add getting transmission stats for sent commands
- Docs and type spec updates

## v0.12.3

Fixes

- Handle multichannel commands that are not appropriately encapsulated

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.12.2

Enhancements

- Add `Grizzly.ZWave.CommandClasses.Hail`
- Add `Grizzly.ZWave.Commands.Hail`
- Support updated Z-Wave spec command params for
  `Grizzly.ZWave.Commands.DoorLockOperationReport`

## v0.12.1

Enhancements

- Add `Grizzly.ZWave.Commands.MultiChannelAggregatedMemberGet`
- Add `Grizzly.ZWave.Commands.MultiChannelAggregatedMemberReport`
- Add `Grizzly.ZWave.Commands.MultiChannelCapabilityGet`
- Add `Grizzly.ZWave.Commands.MultiChannelCommandEncapsulation`
- Add `Grizzly.ZWave.Commands.MultiChannelEndpointFind`
- Add `Grizzly.ZWave.Commands.MultiChannelEndpointFindReport`
- Add `Grizzly.ZWave.CommandClasses.MultiCommand`
- Add `Grizzly.ZWave.Commands.MultiCommandEncapsulation`
- Add `Grizzly.ZWave.CommandClasses.Time`
- Add `Grizzly.ZWave.Commands.DateGet`
- Add `Grizzly.ZWave.Commands.DateReport`
- Add `Grizzly.ZWave.Commands.TimeGet`
- Add `Grizzly.ZWave.Commands.TimeReport`
- Add `Grizzly.ZWave.Commands.TimeOffsetGet`
- Add `Grizzly.ZWave.Commands.TimeOffsetReport`
- Add `Grizzly.ZWave.Commands.TimeOffsetSet`
- Add `Grizzly.ZWave.CommandsClasses.TimeParameters`
- Add `Grizzly.ZWave.Commands.TimeParametersGet`
- Add `Grizzly.ZWave.Commands.TimeParametersReport`
- Add `Grizzly.ZWave.Commands.TimeParametersSet`
- Documentation updates

Fixes

- Some devices send alarm reports that do not match the specification in a
  minor way. So, we allow for parsing of these reports now.
- Fixed internal command class name to module implementation mapping issue
  for `:switch_multilevel_set` and `:switch_multilevel_get` commands.

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.12.0

There is a small breaking change that will only effect you if you hard have
`:water_leak_detected_known_location` and `:water_leak_dropped_known_location`
hard coded into your application for any reason. These are notifications about
water leaks, and so if you have not directly tried to match on or handle logic
about water leak notifications then this breaking change should not effect you.

From a high level this release provides updates to Z-Wave notifications in
terms of command support and package parsing, extra tooling for better
introspection, a handful of new commands and command classes, and helpful
configuration items.

Enhancements

- Add `Grizzly.ZWave.Commands.ApplicationNodeInfoReport`
- Add `Grizzly.ZWave.CommandClass.NodeNaming`
- Add `Grizzly.ZWave.Commands.NodeLocationGet`
- Add `Grizzly.ZWave.Commands.NodeLocationReport`
- Add `Grizzly.ZWave.Commands.NodeLocationSet`
- Add `Grizzly.ZWave.Commands.NodeNameGet`
- Add `Grizzly.ZWave.Commands.NodeNameReport`
- Add `Grizzly.ZWave.Commands.NodeNameSet`
- Add `Grizzly.ZWave.Commands.AlarmGet`
- Add `Grizzly.ZWave.Commands.AlarmSet`
- Add `Grizzly.ZWave.Commands.AlarmEventSupportedGet`
- Add `Grizzly.ZWave.Commands.AlarmEventSupportedReport`
- Add `Grizzly.ZWave.Commands.AlarmTypeSupportedGet`
- Add `Grizzly.ZWave.Commands.AlarmTypeSupportedReport`
- Add `Grizzly.ZWave.Commands.AssociationGroupingsGet`
- Add `Grizzly.ZWave.Commands.AssociationGroupingsReport`
- Add `Grizzly.ZWave.Commands.AssociationRemove`
- Add `Grizzly.ZWave.Commands.AssociationReport`
- Add `Grizzly.ZWave.Commands.AssociationSpecificGroupingsGet`
- Add `Grizzly.ZWave.Commands.AssociationSpecificGroupingsReport`
- Add `Grizzly.ZWave.CommandClasses.MultiChannelAssociation`
- Add `Grizzly.ZWave.Commands.MultiChannelAssociationGroupingsGet`
- Add `Grizzly.ZWave.Commands.MultiChannelAssociationGroupingsReport`
- Add `Grizzly.ZWave.Commands.MultiChannelAssociationRemove`
- Add `Grizzly.ZWave.Commands.MultiChannelAssociationReport`
- Add `Grizzly.ZWave.Commands.MultiChannelAssociationSet`
- Add `Grizzly.ZWave.CommandClass.DeviceResetLocally`
- Add `Grizzly.ZWave.Commands.DeviceResetLocallyNotification`
- Add `Grizzly.ZWave.Commands.LearnModeSet`
- Add `Grizzly.ZWave.Commands.LearnModeSetStatus`
- Add `Grizzly.Inclusions.learn_mode/1`
- Add `Grizzly.Inclusions.learn_mode_stop/0`
- Support version 8 of the `Grizzly.ZWave.Commands.AlarmReport`
- Support parsing naming and location parameters from Z-Wave notifications
- Add `mix zipgateway.cfg` to print out the zipgateway config that Grizzly
  is configured to use.
- Add `Grizzly.list_commands/0` to list all support Z-Wave commands in
  Grizzly.
- Add `Grizzly.commands_for_command_class/1` for listing the Z-Wave commands
  support by Grizzly for a particular command class.
- Add `:handlers` to `:grizzly` configuration options for firmware update and
  inclusion handlers.
- Documentation updates

Fixes

- Parsing the wrong byte for into the wrong notification type
- Invalid type spec for `Grizzly.ZWave.Security.failed_type_from_byte/1`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.11.0

Grizzly now supports parsing alarm/notification parameters as a keyword list of
parameters. This change is breaking because the event parameters use to be the
raw binary we received from the Z-Wave network and now it is a keyword list.

We only support lock and keypad event parameters currently, but this puts into
place the start of being able to support event parameters.

Enhancements

- Support parsing event parameters for lock and keypad operations

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.10.3

Enhancements

- Add `handle_timeout/2` to the `Grizzly.InclusionHandler` behaviour. This
  allows for handling when an inclusion process times out.
- Add `Grizzly.Inclusions.stop/0` force stop any type of inclusion process.
- Add `Grizzly.FirmwareUpdates` module for updating the Z-Wave firmware on
  Z-Wave hardware

Fixes

- not parsing command classes correctly on `Grizzly.ZWave.Commands.NodeAddStatus`
- Not stopping an inclusion process correctly when calling
  `Grizzly.Inclusions.add_node_stop/0`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v.0.10.2

Enhancements

- Add `Grizzly.ZWave.Commands.FailedNodeRemove`
- Add `Grizzly.ZWave.Commands.FailedNodeRemoveStatus`

Fixes

- Sensor types returned from the support sensors report
- Broken link in docs

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v.0.10.1

Enhancements

- Add `Grizzly.ZWave.Commands.ConfigurationGet`
- Add `Grizzly.ZWave.Commands.ConfigurationReport`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.10.0

Removed the parameter `:secure_command_classes` from
`Grizzly.ZWave.Command.NodeInfoCacheReport`. Also updated the param
`:command_classes` to be a keyword list of the various command classes that
the node can have.

The fields in the keyword list are:

- `:non_secure_supported`
- `:non_secure_controlled`
- `:secure_supported`
- `:secure_controlled`

If you are using `:secure_command_classes` for checking if the device is
securely added you can update like this:

```elixir

{:ok, node_info} = Grizzly.Node.get_info(10)

Keyword.get(Grizzly.ZWave.Command.param!(node_info, :command_classes), :secure_controlled)
```

Enhancements

- Add `Grizzly.ZWave.Commands.AssociationGroupCommandListGet`
- Add `Grizzly.ZWave.Commands.AssociationGroupCommandListReport`
- Add `Grizzly.ZWave.Commands.AssociationGroupInfoGet`
- Add `Grizzly.ZWave.Commands.AssociationGroupInfoReport`
- Add `Grizzly.ZWave.Commands.AssociationGroupNameGet`
- Add `Grizzly.ZWave.Commands.AssociationGroupNameReport`
- Add `Grizzly.ZWave.Commands.MultiChannelEndpointGet`
- Add `Grizzly.ZWave.Commands.MultiChannelEndpointReport`

Fixes

- Internal command class name discrepancies

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0

The official `v0.9.0` release!

If you trying to upgrade from `v0.8.x` please see [Grizzly v0.8.0 -> v0.9.0](https://gist.github.com/mattludwigs/b172eaae0831f71df5ab53e2d6066081)
guide and follow the Changelog from the initial `v0.9.0-rc.0` release.

Changes from the last `rc` are:

Enhancements

- Support Erlang 23.0 with Elixir 1.10
- Dep updates and tooling enhancements

Fixes

- miss spellings of command names

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0-rc.4

Enhancements

- Add `Grizzly.ZWave.Commands.FirmwareMDGet`
- Add `Grizzly.ZWave.Commands.FirmwareUpdateMDRequestGet`
- Add `Grizzly.ZWave.Commands.FirmwareUpdateMDRequestReport`
- Add `Grizzly.ZWave.Commands.FirmwareUpdateMDStatusReport`
- Add `Grizzly.ZWave.Commands.FirmwareUpdateMDReport`
- Add `Grizzly.ZWave.Commands.FirmwareUpdateActivationSet`
- Add `Grizzly.ZWave.Commands.FirmwareUpdateActivationReport`
- Remove some dead code

Fixes

- When resetting the controller we were not closing the connections to
  the nodes. This caused some error logging in `zipgateway` and also left
  open unused resources. This could cause problems later when reconnecting
  devices to resources that were already in the system.

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0-rc.3

Enhancements

- Some Z-Wave devices report the wrong value for the switch multilevel
  report so we added support for those values.

Fixes

- When two processes quickly sent the same command to the same device only
  one process would receive the response

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0-rc.2

Deprecated

- `Grizzly.Node.get_node_info/1` - use `Grizzly.Node.get_info/1` instead

Added

- `Grizzly.Node.get_info/1`
- `Grizzly.ZWave.CommandClasses.Supervision`
- `Grizzly.ZWave.Commands.SupervisionGet`
- `Grizzly.ZWave.Commands.SupervisionReport`
- `Grizzly.ZWave.CommandClasses.SensorBinary`
- `Grizzly.ZWave.Commands.SensorBinaryGet`
- `Grizzly.ZWave.Commands.SensorBinaryReport`

Enhancements

- Support for `DoorLockOperationReport` >= V3 parsing

Fixes

- Bad parsing of `NodAddStatus` `:failed` value

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0-rc.1

Breaking Changes

- `Grizzly.ZWave.IconTypes` removed `icon_type` from the atom values of the
  icon name.
- `Grizzly.ZWave.DeviceTypes.icon_name()` ->
  `Grizzly.ZWave.DeviceTypes.name()`
- `Grizzly.ZWave.DeviceTypes.icon_integer()` ->
  `Grizzly.ZWave.DeviceTypes.value()`

Enhancements

- Doc updates
- Internal code quality
- Deps updates
- Better types around DSKs
- CI support for elixir versions 1.8, 1.9, and 1.10
- Support all versions of the meter report
- Support a low battery report

## v0.9.0-rc.0

For more detailed guide to the breaking changes and how to upgrade please see
our [Grizzly v0.8.0 -> v0.9.0](https://gist.github.com/mattludwigs/b172eaae0831f71df5ab53e2d6066081) guide.

This release presents a simpler API, faster boot time, more robustness in Z-Wave communication,
and resolves all open issues on Grizzly that were reported as bugs.

### Removed APIs

- `Grizzly.Node` struct
- `Grizzly.Conn` module
- `Grizzly.Notifications` module
- `Grizzly.Packet` module
- `Grizzly.close_connection`
- `Grizzly.command_class_versions_known?`
- `Grizzly.update_command_class_versions`
- `Grizzly.start_learn_mode`
- `Grizzly.get_command_class_version`
- `Grizzly.has_command_class`
- `Grizzly.connected?`
- `Grizzly.has_command_class_names`
- `Grizzly.config`
- `Grizzly.Network.busy?`
- `Grizzly.Network.ready?`
- `Grizzly.Network.get_state`
- `Grizzly.Network.set_state`
- `Grizzly.Network.get_node`
- `Grizzly.Node.new`
- `Grizzly.Node.update`
- `Grizzly.Node.put_ip`
- `Grizzly.Node.get_ip`
- `Grizzly.Node.connect`
- `Grizzly.Node.disconnect`
- `Grizzly.Node.make_config`
- `Grizzly.Node.has_command_class?`
- `Grizzly.Node.connected?`
- `Grizzly.Node.command_class_names`
- `Grizzly.Node.update_command_class_versions`
- `Grizzly.Node.get_command_class_version`
- `Grizzly.Node.command_class_version_known?`
- `Grizzly.Node.update_command_class`
- `Grizzly.Node.put_association`
- `Grizzly.Node.get_association_list`
- `Grizzly.Node.configure_association`
- `Grizzly.Node.get_network_information`
- `Grizzly.Node.initialize_command_versions`

### Moved APIs

- `Grizzly.reset_controller` -> `Grizzly.Network.reset_controller`
- `Grizzly.get_nodes` -> `Grizzly.Network.get_node_ids`
- `Grizzly.get_node_info` -> `Grizzly.Node.get_node_info`
- `Grizzly.Notifications.subscribe` -> `Grizzly.subscribe_command` and
  `Grizzly.subscribe_commands`
- `Grizzly.Notifications.unsubscribe` -> `Grizzly.unsubscribe`
- `Grizzly.add_node` -> `Grizzly.Inclusions.add_node`
- `Grizzly.remove_node` -> `Grizzly.Inclusions.remove_node`
- `Grizzly.add_node_stop` -> `Grizzly.Inclusions.add_node_stop`
- `Grizzly.remove_node_stop` -> `Grizzly.Inclusions.remove_node_stop`
- `Grizzly.Client` -> `Grizzly.Transport`
- `Grizzly.Security` -> `Grizzly.ZWave.Security`
- `Grizzly.DSK` -> `Grizzly.ZWave.DSK`
- `Grizzly.Node.add_lifeline_group` -> `Grizzly.Node.set_lifeline_association`

We moved all the commands and command classes to be under the the
`Grizzly.ZWave` module namespace and refactored the command behaviour.

### `Grizzly.send_command` Changes

The main API function to Grizzly has changed in that it only takes a node id,
command name (atom), command args, and command options.

Also it no longer returns a plain map when there is data to report back from
a Z-Wave node but it will return `{:ok, %Grizzly.ZWave.Command{}}`.

Please see `Grizzly` and `Grizzly.ZWave.Command` docs for more information.

### Connections

Grizzly uses the `zipgateway` binary under the hood. The binary has its own
networking stack and provides a DTLS server for us to connect to. Prior to
Grizzly v0.9.0 we greatly exposed that implementation detail. However, starting
in Grizzly v0.9.0 we have hidden that implementation detail away and all
connection functionally is handle by Grizzly internally. This leaves the
consumer of Grizzly to just work about sending and receiving commands.

If you are using `%Grizzly.Conn{}` directly this is no longer available and you
should upgrade to just using the node id you were sending commands to.

### When Grizzly is Ready

We use to send a notification to let the consumer to know when Grizzly is
read. Staring in v0.9.0 the consumer needs to configure Grizzly's runtime
with the `on_ready` module, function, arg callback.

```elixir
config :grizzly,
  runtime: [
    on_ready: {MyApp, :some_function, []}
  ]
```

See `Grizzly.Runtime` for more details

### Inclusion Handler Behaviour

Adding and removing a Z-Wave node can be a very interactive process that
involves users being able to talk to the including controller and device. The
way Grizzly < v0.9.0 did it wasn't vary useful or robust. By adding the the
inclusion handler behaviour we allow the consumer to have full control over the
inclusion process, enabling closer to Z-Wave specification inclusion process.

See `Grizzly.InclusionHandler` and `Grizzly.Inclusions` for more information.

### Command Handler Behaviour

If you need to handle a Z-Wave command lifecycle differently than the default
Grizzly implementation you can make your own handler and pass it into
`Grizzly.send_command` as an option:

```elixir
Grizzly.send_command(node_id, :switch_binary_set, [value: :on], handler: MyHandler)
```

See `Grizzly.CommandHandler` for more information.

### Supporting Commands

At the point of the `rc.0` release are not fully 100% supporting the same
commands as in < v0.8.8, but we are really close. The commands that we haven't
pulled over are not critical to average Z-Wave device control. We will work to
get all the commands back into place.

Thank you to Jean-Francois Cloutier for contributing so much to this release.

## v0.8.8

- Enhancements
  - Make Z-Wave versions standard version formatting
- Fixes
  - Paring the FirmwareMD report for version 5
  - Fix spec for queued commands

## v0.8.7

- Enhancements
  - Support `FIRMWARE_UPDATE_MD` meta data report command v5

## v0.8.6

- Fixes
  - duplicate fields on the `Grizzly.Node` struct

## v0.8.5

- Fixes
  - various spelling and documentation fixes
  - dialzyer fixes

## v0.8.4

- Fixes
  - Handle when there are no nodes in the node provisioning list when
    requesting all the DSKs.

## v0.8.3

- Enhancements
  - Support Wake Up v2 and Multi Channel Association v3

## v0.8.2

- Enhancements
  - Support SWITCH_BINARY_REPORT version 2

## v0.8.1

- Enhancements
  - Update docs and resources
- Fixes
  - An issue when the unsolicited message server would cause a
    no match error that propagated up the supervision tree

Thank you to those who contributed to this release:

- Ryan Winchester

## v0.8.0

Adds support for handling SmartStart meta extension fields.

These fields give more information about the current status, inclusion methods,
and product information for the SmartStart device.

There are two breaking changes:

1. All SmartStart meta extensions were moved from `Grizzly.CommandClass.NodeProvisioning`
   namespace into the `Grizzly.SmartStart.MetaExtension` namespace.
2. Upon finalizing the meta extension behaviour and API we made changes to how
   previously supported meta extensions worked. Namely, we added a `new/1`
   callback that does parameter validation, and returns `{:ok, MetaExtension.t()}`.
   This breaks the pervious behaviour of `to_binary/1` functions in perviously
   implemented meta extensions.

- Enhancements
  - Full support for SmartStart meta extensions
  - Add `meta_extensions` field to `Grizzly.CommandClass.NodeProvisioning`
    commands that can handle meta extensions
  - Update `Grizzly.Conn.Server.Config` docs
- Fixes
  - Invalid keep alive (heart beat) interval
  - Set correct constraints on `Time` command offset values

Thank you to those who contributed to this release:

- Jean-Francois Cloutier
- Ryan Winchester

## v0.7.0

Introduces SmartStart support!

SmartStart will allow you to pair a device to a Z-Wave controller with out
turning the device on. Devices that support SmartStart will have a device
specific key (DSK) that you can provide to the controller prior to turning on
the device.

```elixir
iex> Grizzly.send_command(Grizzly.Controller, Grizzly.CommandClass.NodeProvisioning.Set, dsk: dsk)
:ok
```

After running the above command you can plug in your SmartStart device and the
controller will try to join the Z-Wave network automatically.

As a note, your controller might not have the necessary firmware to have SmartStart.

To verify this you can use `RingLogger` to read `zipgateway` logs which at the start
will log if the controller supports SmartStart.

### Breaking Changes

Breaking change to the return value of sending `Grizzly.CommandClass.ZipNd.InvNodeSolicitation`.

When using that function `send_command` would return
`{:ok, {:node_ip, node_id, ip_address}}` but now it returns
`{:ok, %{ip_address: ip_address, node_id: node_id, home_id: home_id}}`.

- Enhancements
  - SmartStart support through the `NodeProvisioning` command class
  - Added `home_id` field to `Grizzly.Node.t()`
  - Support fetching `home_id` of the Z-Wave nodes when fetching
    Z-Wave information about the node

## v0.6.6

- Fixes
  - Application start failure when providing the correct
    data structure to the `zipgateway_cfg` configuration
    field

## v0.6.5

- Enhancements
  - Support `GetDSK` command
  - Support `FailedNodeRemove` command
  - Allow `zipgateway_path` configuration
  - Generate the `zipgateway.cfg` to allow device specific
    information to be passed into the `zipgateway` runtime.

## v0.6.4

- Enhancements
  - Validation of UserCode arguments to help ensure usage of Grizzly
    follows the Z-Wave specification

## v0.6.3

- Enhancements
  - Supports AssociationGroupInformation Command Class

## v0.6.2

- Enhancements
  - Remove the dependence on `pidof` allowing `grizzly` to work on any nerves
    device without the need of `busybox`

### v0.6.1

- Enhancements
  - Update commands `IntervalGet` and `ManufacturerSpecificGet` to be more
    consistent
  - Better handling of invalid `ManufacturerSpecific` info received from
    devices

### v0.6.0

Changed `Grizzly.CommandClass.CommandClassVersion` to `Grizzly.CommandClass.Version`
and changed `Grizzly.CommandClass.CommandClassVersion.Get` to
`Grizzly.CommandClass.Version.CommandClassGet` as these names reflect the Z-Wave
specification better.

If you only have used `Grizzly.get_command_class_version/2` and the related function
in `Grizzly.Node` module this change should not effect you.

- Enhancements
  - Add support for:
    - MultiChannelAssociation Command Class
    - WakeUp Command Class NoMoreInformation command
    - Complete Association Command Class
    - ZwaveplusInfo Command Class
    - Version Get Command
  - Clean up docs
  - Renamed `Grizzly.CommandClass.CommandClassVersion` to `Grizzly.CommandClass.Version`
  - Renamed `Grizzly.CommandClass.CommandClassVersion.Get` to
    `Grizzly.CommandClass.Version.CommandClassGet`

### v0.5.0

Introduces `Grizzly.Command.EncodeError` exception and updates encoding and
decoding functions to return tagged tuples. We now use these things when trying
to send a command via `Grizzly.send_command/3` so if you have invalid command
arguments we can provide useful error handling with
`{:error, Grizzly.Command.EncodeError.t()}`. The `EncodeError.t()` implements
Elixir's exception behaviour so you can leverage the standard library to
work with the exception.

Unless you have implemented custom commands or used one of the many command
encoders or decodes explicitly this update should not affect you too much. If
you have used the encoder/decoders explicitly please see the documentation for
the ones you have used to see the updated API. If you have written a command we
encourage you to validate the arguments and return the `{:error, EncodeError.t()}`
to improve the usability of and robustness your command. The new
`Grizzly.Command.Encoding` module provides some useful functionality for
validating specs for command arguments.

- Enhancements
  - Provide command argument validation and error handling via
    `Grizzly.Command.EncodeError.()`
  - Update all the command arg encoder/decoder to use tagged
    tuples for better handling of invalid command arguments
  - Introduces new `Grizzly.Command.Encoding` modules for helping
    validate command argument specifications
- Fixes
  - Crashes when providing invalid command arguments

### v0.4.3

- Enhancements
  - Support Powerlevel command class
  - Doc clean up
  - `Grizzly.send_command/2` and `Grizzly.send_command/3`
    can be passed a node id instead of a node.

### v0.4.2

- Enhancements
  - Support NoOperation command class

### v0.4.1

- Enhancements
  - Add support for Network Management Installation Maintenance
  - Updates to docs and examples

### v0.4.0

Changed how configuration works.

Grizzly now requires the serial port to be configured:

```elixir
config :grizzly,
  serial_port: "/dev/ttyACM0"
```

Also added the `pidof_bin` configuration option to allow official
Nerves systems to work with some of the Grizzly scripts the call
that utility by using the [busybox](https://hex.pm/packages/busybox) package and
pointing to the executable of `pidof` that is compiled with `busybox`.

If you are using a custom system you can add that utility to the
busybox config, and not need to use this configuration option.

```elixir
config :grizzly,
  pidof_bin: "/srv/erlang/lib/busybox-0.1.2/priv/bin/pidof"
```

Double check the version of busybox you are using and make sure that
version matches the version in the `pidof_bin` path.

Changed `run_grizzly_bin` to `run_zipgateway_bin`.

## v0.3.1

- Enhancements
  - Implement multilevel sensor command to get supported sensor types

## v0.3.0

The big change here is removing the in memory
cache for devices on the network. Most common
use cases will be for a consuming application to
hold on to the network device information and apply
some costume logic to now that is managed.

Also, we would have to keep both the external
and internal cache in sync, which is really hard
and was creating an odd event based system, which
also lends itself to complexity.

### Breaking Changes

`Grizzly.list_nodes()` -> `Grizzly.get_nodes()`

This is mostly because before we were listing nodes
from a cache, and now we are getting nodes from the
Z-Wave network.

Also with `get_nodes` we don't automatically connect
to the nodes. So getting and connecting to all nodes
on the Z-Wave network might look something like this:

```elixir
def get_and_connect() do
  case Grizzly.get_nodes() do
    {:ok, nodes} -> Enum.map(nodes, &Grizzly.Node.connect/1)
    error -> error
  end
end
```

`Grizzly.update_command_class_versions/2` -> `Grizzly.update_command_class_versions/1`

Before we would pass if the update would be async or not
after reviewing how this gets used it made sense to
always do it sync. Also it returns a `Node.t()` now
with the command classes updated with the version.

This is the same change found in `Grizzly.Node.update_command_class_versions`

`Grizzly.command_class_version/3` -> `Grizzly.get_command_class_version/2`

Removed the `use_cache` param as there is no longer a cache.

Same change found in `Grizzly.Node.get_command_class_version`

- Enhancements
  - Support `Grizzly.CommandClass.Time` command class
  - Support `Grizzly.CommandClass.TimeParameters` GET and SET commands
  - Support `Grizzly.CommandClass.ScheduleEntryLock` command class
  - `Grizzly.Notifications.subscribe_all/1` - subscribe to many notifications at once
  - `Grizzly.CommandClass.name/1` - get the name of the command class
  - `Grizzly.CommandClass.version/1` - get the version of the command class
  - `Grizzly.Network.get_nodes/0` - get the nodes on the network
  - `Grizzly.Network.get_node/1` - get a node by node id from the network
  - `Grizzly.Network.get_node_info/1` - get node information about a node via node id
  - `Grizzly.Node.get_ip/1` - can now take either a `Node.t()` or a node id
- Updates
  - Docs and type clean up
- Fixes
  - Timeout when getting command class versions

## v0.2.1

- Updates
  - Support for the time command class
- Fixes
  - Time-boxing of getting a command class version

## v0.2.0

- Fixes
  - Logging with old `ZipGateway` label is now `Grizzly`
  - Fix queued API from `{ZipGateway, :queued_response, ref, response}`
    to `{Grizzly, :queued_response, ref, response}`
  - Fix timeout error when waiting for DTLS server from the
    `zipgateway` side

[v8.7.1]: https://github.com/smartrent/grizzly/compare/v8.7.0..v8.7.1
[v8.7.0]: https://github.com/smartrent/grizzly/compare/v8.6.9..v8.7.0
[v8.6.9]: https://github.com/smartrent/grizzly/compare/v8.6.8..v8.6.9
[v8.6.8]: https://github.com/smartrent/grizzly/compare/v8.6.7..v8.6.8
[v8.6.7]: https://github.com/smartrent/grizzly/compare/v8.6.6..v8.6.7
[v8.6.6]: https://github.com/smartrent/grizzly/compare/v8.6.5..v8.6.6
[v8.6.5]: https://github.com/smartrent/grizzly/compare/v8.6.4..v8.6.5
[v8.6.4]: https://github.com/smartrent/grizzly/compare/v8.6.3..v8.6.4
[v8.6.3]: https://github.com/smartrent/grizzly/compare/v8.6.2..v8.6.3
[v8.6.2]: https://github.com/smartrent/grizzly/compare/v8.6.1..v8.6.2
[v8.6.1]: https://github.com/smartrent/grizzly/compare/v8.6.0..v8.6.1
[v8.6.0]: https://github.com/smartrent/grizzly/compare/v8.5.3..v8.6.0
[v8.5.3]: https://github.com/smartrent/grizzly/compare/v8.5.2..v8.5.3
[v8.5.2]: https://github.com/smartrent/grizzly/compare/v8.5.1..v8.5.2
[v8.5.1]: https://github.com/smartrent/grizzly/compare/v8.5.0..v8.5.1
[v8.5.0]: https://github.com/smartrent/grizzly/compare/v8.4.0..v8.5.0
[v8.4.0]: https://github.com/smartrent/grizzly/compare/v8.3.0..v8.4.0
[v8.3.0]: https://github.com/smartrent/grizzly/compare/v8.2.3..v8.3.0
[v8.2.3]: https://github.com/smartrent/grizzly/compare/v8.2.2..v8.2.3
[v8.2.2]: https://github.com/smartrent/grizzly/compare/v8.2.1..v8.2.2
[v8.2.1]: https://github.com/smartrent/grizzly/compare/v8.2.0..v8.2.1
[v8.2.0]: https://github.com/smartrent/grizzly/compare/v8.1.0..v8.2.0
[v8.1.0]: https://github.com/smartrent/grizzly/compare/v8.0.1..v8.1.0
[v8.0.1]: https://github.com/smartrent/grizzly/compare/v8.0.0..v8.0.1
[v8.0.0]: https://github.com/smartrent/grizzly/compare/v7.4.2..v8.0.0
[v7.4.2]: https://github.com/smartrent/grizzly/compare/v7.4.1..v7.4.2
[v7.4.1]: https://github.com/smartrent/grizzly/compare/v7.4.0..v7.4.1
[v7.4.0]: https://github.com/smartrent/grizzly/compare/v7.3.0..v7.4.0
[v7.3.0]: https://github.com/smartrent/grizzly/compare/v7.2.0..v7.3.0
[v7.2.0]: https://github.com/smartrent/grizzly/compare/v7.1.4..v7.2.0
[v7.1.4]: https://github.com/smartrent/grizzly/compare/v7.1.3..v7.1.4
[v7.1.3]: https://github.com/smartrent/grizzly/compare/v7.1.2..v7.1.3
[v7.1.2]: https://github.com/smartrent/grizzly/compare/v7.1.1..v7.1.2
[v7.1.1]: https://github.com/smartrent/grizzly/compare/v7.1.0..v7.1.1
[v7.1.0]: https://github.com/smartrent/grizzly/compare/v7.0.4..v7.1.0
[v7.0.4]: https://github.com/smartrent/grizzly/compare/v7.0.3..v7.0.4
[v7.0.3]: https://github.com/smartrent/grizzly/compare/v7.0.2..v7.0.3
[v7.0.2]: https://github.com/smartrent/grizzly/compare/v7.0.1..v7.0.2
[v7.0.1]: https://github.com/smartrent/grizzly/compare/v7.0.0..v7.0.1
[v7.0.0]: https://github.com/smartrent/grizzly/compare/v6.8.8..v7.0.0
[v6.8.8]: https://github.com/smartrent/grizzly/compare/v6.8.7..v6.8.8
[v6.8.7]: https://github.com/smartrent/grizzly/compare/v6.8.6..v6.8.7
[v6.8.6]: https://github.com/smartrent/grizzly/compare/v6.8.5..v6.8.6
[v6.8.5]: https://github.com/smartrent/grizzly/compare/v6.8.4..v6.8.5
[v6.8.4]: https://github.com/smartrent/grizzly/compare/v6.8.3..v6.8.4
[v6.8.3]: https://github.com/smartrent/grizzly/compare/v6.8.2..v6.8.3
[v6.8.2]: https://github.com/smartrent/grizzly/compare/v6.8.1..v6.8.2
[v6.8.1]: https://github.com/smartrent/grizzly/compare/v6.8.0..v6.8.1
[v6.8.0]: https://github.com/smartrent/grizzly/compare/v6.7.1..v6.8.0
[v6.7.1]: https://github.com/smartrent/grizzly/compare/v6.7.0..v6.7.1
[v6.7.0]: https://github.com/smartrent/grizzly/compare/v6.6.1..v6.7.0
[v6.6.1]: https://github.com/smartrent/grizzly/compare/v6.6.0..v6.6.1
[v6.6.0]: https://github.com/smartrent/grizzly/compare/v6.5.1..v6.6.0
[v6.5.1]: https://github.com/smartrent/grizzly/compare/v6.5.0..v6.5.1
[v6.5.0]: https://github.com/smartrent/grizzly/compare/v6.4.0..v6.5.0
[v6.4.0]: https://github.com/smartrent/grizzly/compare/v6.3.0..v6.4.0
[v6.3.0]: https://github.com/smartrent/grizzly/compare/v6.2.0..v6.3.0
[v6.2.0]: https://github.com/smartrent/grizzly/compare/v6.1.1..v6.2.0
[v6.1.1]: https://github.com/smartrent/grizzly/compare/v6.1.0..v6.1.1
[v6.1.0]: https://github.com/smartrent/grizzly/compare/v6.0.1..v6.1.0
[v6.0.1]: https://github.com/smartrent/grizzly/compare/v6.0.0..v6.0.1
[v6.0.0]: https://github.com/smartrent/grizzly/compare/v5.4.1..v6.0.0
[v5.4.1]: https://github.com/smartrent/grizzly/compare/v5.4.0..v5.4.1
[v5.4.0]: https://github.com/smartrent/grizzly/compare/v5.3.0..v5.4.0
[v5.3.0]: https://github.com/smartrent/grizzly/compare/v5.2.8..v5.3.0
[v5.2.8]: https://github.com/smartrent/grizzly/compare/v5.2.7..v5.2.8
[v5.2.7]: https://github.com/smartrent/grizzly/compare/v5.2.6..v5.2.7
[v5.2.6]: https://github.com/smartrent/grizzly/compare/v5.2.5..v5.2.6
[v5.2.5]: https://github.com/smartrent/grizzly/compare/v5.2.4..v5.2.5
[v5.2.4]: https://github.com/smartrent/grizzly/compare/v5.2.3..v5.2.4
[v5.2.3]: https://github.com/smartrent/grizzly/compare/v5.2.2..v5.2.3
[v5.2.2]: https://github.com/smartrent/grizzly/compare/v5.2.1..v5.2.2
[v5.2.1]: https://github.com/smartrent/grizzly/compare/v5.2.0...v5.2.1
[v5.2.0]: https://github.com/smartrent/grizzly/compare/v5.1.2...v5.2.0
[v5.1.2]: https://github.com/smartrent/grizzly/compare/v5.1.1...v5.1.2
[v5.1.1]: https://github.com/smartrent/grizzly/compare/v5.1.0...v5.1.1
[v5.1.0]: https://github.com/smartrent/grizzly/compare/v5.0.2...v5.1.0
[v5.0.2]: https://github.com/smartrent/grizzly/compare/v5.0.1...v5.0.2
[v5.0.1]: https://github.com/smartrent/grizzly/compare/v5.0.0...v5.0.1
[v5.0.0]: https://github.com/smartrent/grizzly/compare/v4.0.1...v5.0.0
[v4.0.1]: https://github.com/smartrent/grizzly/compare/v4.0.0...v4.0.1
[v4.0.0]: https://github.com/smartrent/grizzly/compare/v3.0.0...v4.0.0
[v3.0.0]: https://github.com/smartrent/grizzly/compare/v2.1.0...v3.0.0
[v2.1.0]: https://github.com/smartrent/grizzly/compare/v2.0.0...v2.1.0
[v2.0.0]: https://github.com/smartrent/grizzly/compare/v1.0.1...v2.0.0
[v1.0.1]: https://github.com/smartrent/grizzly/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/smartrent/grizzly/compare/v0.22.7...v1.0.0
[v0.22.7]: https://github.com/smartrent/grizzly/compare/v0.22.6...v0.22.7
[v0.22.6]: https://github.com/smartrent/grizzly/compare/v0.22.5...v0.22.6
[v0.22.5]: https://github.com/smartrent/grizzly/compare/v0.22.4...v0.22.5
[v0.22.4]: https://github.com/smartrent/grizzly/compare/v0.22.3...v0.22.4
[v0.22.3]: https://github.com/smartrent/grizzly/compare/v0.22.2...v0.22.3
[v0.22.2]: https://github.com/smartrent/grizzly/compare/v0.22.1...v0.22.2
[v0.22.1]: https://github.com/smartrent/grizzly/compare/v0.22.0...v0.22.1
[v0.22.0]: https://github.com/smartrent/grizzly/compare/v0.21.1...v0.22.0
[v0.21.1]: https://github.com/smartrent/grizzly/compare/v0.21.0...v0.21.1
[v0.21.0]: https://github.com/smartrent/grizzly/compare/v0.20.2...v0.21.0
[v0.20.2]: https://github.com/smartrent/grizzly/compare/v0.20.1...v0.20.2
[v0.20.1]: https://github.com/smartrent/grizzly/compare/v0.20.0...v0.20.1
[v0.20.0]: https://github.com/smartrent/grizzly/compare/v0.19.1...v0.20.0
[v0.19.1]: https://github.com/smartrent/grizzly/compare/v0.19.0...v0.19.1
[v0.19.0]: https://github.com/smartrent/grizzly/compare/v0.18.3...v0.19.0
[v0.18.3]: https://github.com/smartrent/grizzly/compare/v0.18.2...v0.18.3
[v0.18.2]: https://github.com/smartrent/grizzly/compare/v0.18.1...v0.18.2
[v0.18.1]: https://github.com/smartrent/grizzly/compare/v0.18.0...v0.18.1
[v0.18.0]: https://github.com/smartrent/grizzly/compare/v0.17.8...v0.18.0
[v0.17.7]: https://github.com/smartrent/grizzly/compare/v0.17.6...v0.17.7
[v0.17.6]: https://github.com/smartrent/grizzly/compare/v0.17.5...v0.17.6
[v0.17.5]: https://github.com/smartrent/grizzly/compare/v0.17.4...v0.17.5
[v0.17.4]: https://github.com/smartrent/grizzly/compare/v0.17.3...v0.17.4
[v0.17.3]: https://github.com/smartrent/grizzly/compare/v0.17.2...v0.17.3
[v0.17.2]: https://github.com/smartrent/grizzly/compare/v0.17.1...v0.17.2
[v0.17.1]: https://github.com/smartrent/grizzly/compare/v0.17.0...v0.17.1
[v0.17.0]: https://github.com/smartrent/grizzly/compare/v0.16.2...v0.17.0
[v0.16.2]: https://github.com/smartrent/grizzly/compare/v0.16.1...v0.16.2
[v0.16.1]: https://github.com/smartrent/grizzly/compare/v0.16.0...v0.16.1
[v0.16.0]: https://github.com/smartrent/grizzly/compare/v0.15.11...v0.16.0
[v0.15.11]: https://github.com/smartrent/grizzly/compare/v0.15.10...v0.15.11
[v0.15.10]: https://github.com/smartrent/grizzly/compare/v0.15.9...v0.15.10
[v0.15.9]: https://github.com/smartrent/grizzly/compare/v0.15.8...v0.15.9
[v0.15.8]: https://github.com/smartrent/grizzly/compare/v0.15.7...v0.15.8
[v0.15.7]: https://github.com/smartrent/grizzly/compare/v0.15.6...v0.15.7
[v0.15.6]: https://github.com/smartrent/grizzly/compare/v0.15.5...v0.15.6
[v0.15.5]: https://github.com/smartrent/grizzly/compare/v0.15.4...v0.15.5
[v0.15.4]: https://github.com/smartrent/grizzly/compare/v0.15.3...v0.15.4
[v0.15.3]: https://github.com/smartrent/grizzly/compare/v0.15.2...v0.15.3
[v0.15.2]: https://github.com/smartrent/grizzly/compare/v0.15.1...v0.15.2
[v0.15.1]: https://github.com/smartrent/grizzly/compare/v0.15.0...v0.15.1
[v0.15.0]: https://github.com/smartrent/grizzly/compare/v0.14.8...v0.15.0
[v0.14.8]: https://github.com/smartrent/grizzly/compare/v0.14.7...v0.14.8
[v0.14.7]: https://github.com/smartrent/grizzly/compare/v0.14.6...v0.14.7
[v0.14.6]: https://github.com/smartrent/grizzly/compare/v0.14.5...v0.14.6
[v0.14.5]: https://github.com/smartrent/grizzly/compare/v0.14.4...v0.14.5
[v0.14.4]: https://github.com/smartrent/grizzly/compare/v0.14.3...v0.14.4
[v0.14.3]: https://github.com/smartrent/grizzly/compare/v0.14.2...v0.14.3
