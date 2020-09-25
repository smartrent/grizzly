## Changelog

## v0.14.7 - 2020-09-25

### Added

- Added `Grizzly.ZWave.Commands.FailedNodeListReport` command

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.14.6 - 2020-09-18

### Added

- Cookbook documentation for common uses of Grizzly

### Changed

- Reduced the amount of logging

## v0.14.5 - 2020-09-02

Fixed
 - Commands with aggregated reports did not aggregate the results as expected
 - Commands with aggregated reports would crash if that device was also
   handling another command due to the aggregate handler assuming that only one
   command was being processed at one time

## v0.14.4 - 2020-09-01

Added
  - Full support for `ThermostatFanMode` mode types

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.14.3 - 2020-08-31

Fixed
  - Fix the start order of the connection supervisor and Z-Wave ready checker
    to ensure the supervisor process is alive before trying to test the
    connection

## v0.14.2

Added
  * `Grizzly.ZWave.CRC` module for CRC functions related to the Z-Wave protocol

Removed
  * `crc` dependency

## v0.14.1

Enhancements
  * Support `zipgateway` 7.14.01
  * Add `Grizzly.ZWave.CommandClasses.CentralScene`
  * Add `Grizzly.ZWave.Commands.CentralSceneConfigurationGet`
  * Add `Grizzly.ZWave.Commands.CentralSceneConfigurationSet`
  * Add `Grizzly.ZWave.Commands.CentralSceneConfigurationReport`
  * Add `Grizzly.ZWave.Commands.CentralSceneNotification`
  * Add `Grizzly.ZWave.Commands.CentralSceneSupportedGet`
  * Add `Grizzly.ZWave.Commands.CentralSceneSupportedReport`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.14.0

This breaking change has to do with how Grizzly is started. It is no longer an
application. Grizzly exposes the `Grizzly.Supervisor` module for a consuming
application to add to its supervision tree. All other APIs are backwards capable.

See the [upgrade guide](https://gist.github.com/mattludwigs/bb312906b1bf85a021080c45d1562f2b)
for more specifics on how to upgrade.

Breaking Changes
  * Grizzly is not an OTP application anymore and will need to be started
    manually via the new `Grizzly.Supervisor` module
  * All application config/mix config options are not used
  * Removed the `Grizzly.Runtime` module

Enhancements
  * Add `Grizzly.Supervisor` module
  * Add `Grizzly.ZWave.CommandClasses.Indicator`
  * Add `Grizzly.ZWave.Commands.IndicatorGet`
  * Add `Grizzly.ZWave.Commands.IndicatorSet`
  * Add `Grizzly.ZWave.Commands.IndicatorReport`
  * Add `Grizzly.ZWave.Commands.IndicatorSupportedGet`
  * Add `Grizzly.ZWave.Commands.IndicatorSupportedReport`
  * Add `Grizzly.ZWave.CommandClasses.Antitheft`
  * Add `Grizzly.ZWave.Commands.AntitheftGet`
  * Add `Grizzly.ZWave.Commands.AntitheftReport`
  * Add `Grizzly.ZWave.CommandClasses.AntitheftUnlock`
  * Add `Grizzly.ZWave.Commands.AntitheftUnlockSet`
  * Add `Grizzly.ZWave.Commands.AntitheftUnlockGet`
  * Add `Grizzly.ZWave.Commands.AntitheftUnlockReport`
  * Add `Grizzly.ZWave.Commands.ConfigurationBulkGet`
  * Add `Grizzly.ZWave.Commands.ConfigurationBulkSet`
  * Add `Grizzly.ZWave.Commands.ConfigurationBulkReport`
  * Add `Grizzly.ZWave.Commands.ConfigurationPropertiesGet`
  * Add `Grizzly.ZWave.CommandClasses.ApplicationStatus`
  * Add `Grizzly.ZWave.Commands.ApplicationBusy`
  * Add `Grizzly.ZWave.Commands.ApplicationRejectedRequest`

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
  * Add `Grizzly.Report`
  * Add getting transmission stats for sent commands
  * Docs and type spec updates

## v0.12.3

Fixes
  * Handle multichannel commands that are not appropriately encapsulated

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.12.2

Enhancements
  * Add `Grizzly.ZWave.CommandClasses.Hail`
  * Add `Grizzly.ZWave.Commands.Hail`
  * Support updated Z-Wave spec command params for
    `Grizzly.ZWave.Commands.DoorLockOperationReport`

## v0.12.1

Enhancements
  * Add `Grizzly.ZWave.Commands.MultiChannelAggregatedMemberGet`
  * Add `Grizzly.ZWave.Commands.MultiChannelAggregatedMemberReport`
  * Add `Grizzly.ZWave.Commands.MultiChannelCapabilityGet`
  * Add `Grizzly.ZWave.Commands.MultiChannelCommandEncapsulation`
  * Add `Grizzly.ZWave.Commands.MultiChannelEndpointFind`
  * Add `Grizzly.ZWave.Commands.MultiChannelEndpointFindReport`
  * Add `Grizzly.ZWave.CommandClasses.MultiCommand`
  * Add `Grizzly.ZWave.Commands.MultiCommandEncapsulation`
  * Add `Grizzly.ZWave.CommandClasses.Time`
  * Add `Grizzly.ZWave.Commands.DateGet`
  * Add `Grizzly.ZWave.Commands.DateReport`
  * Add `Grizzly.ZWave.Commands.TimeGet`
  * Add `Grizzly.ZWave.Commands.TimeReport`
  * Add `Grizzly.ZWave.Commands.TimeOffsetGet`
  * Add `Grizzly.ZWave.Commands.TimeOffsetReport`
  * Add `Grizzly.ZWave.Commands.TimeOffsetSet`
  * Add `Grizzly.ZWave.CommandsClasses.TimeParameters`
  * Add `Grizzly.ZWave.Commands.TimeParametersGet`
  * Add `Grizzly.ZWave.Commands.TimeParametersReport`
  * Add `Grizzly.ZWave.Commands.TimeParametersSet`
  * Documentation updates

Fixes
  * Some devices send alarm reports that do not match the specification in a
    minor way. So, we allow for parsing of these reports now.
  * Fixed internal command class name to module implementation mapping issue
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
  * Add `Grizzly.ZWave.Commands.ApplicationNodeInfoReport`
  * Add `Grizzly.ZWave.CommandClass.NodeNaming`
  * Add `Grizzly.ZWave.Commands.NodeLocationGet`
  * Add `Grizzly.ZWave.Commands.NodeLocationReport`
  * Add `Grizzly.ZWave.Commands.NodeLocationSet`
  * Add `Grizzly.ZWave.Commands.NodeNameGet`
  * Add `Grizzly.ZWave.Commands.NodeNameReport`
  * Add `Grizzly.ZWave.Commands.NodeNameSet`
  * Add `Grizzly.ZWave.Commands.AlarmGet`
  * Add `Grizzly.ZWave.Commands.AlarmSet`
  * Add `Grizzly.ZWave.Commands.AlarmEventSupportedGet`
  * Add `Grizzly.ZWave.Commands.AlarmEventSupportedReport`
  * Add `Grizzly.ZWave.Commands.AlarmTypeSupportedGet`
  * Add `Grizzly.ZWave.Commands.AlarmTypeSupportedReport`
  * Add `Grizzly.ZWave.Commands.AssociationGroupingsGet`
  * Add `Grizzly.ZWave.Commands.AssociationGroupingsReport`
  * Add `Grizzly.ZWave.Commands.AssociationRemove`
  * Add `Grizzly.ZWave.Commands.AssociationReport`
  * Add `Grizzly.ZWave.Commands.AssociationSpecificGroupingsGet`
  * Add `Grizzly.ZWave.Commands.AssociationSpecificGroupingsReport`
  * Add `Grizzly.ZWave.CommandClasses.MultiChannelAssociation`
  * Add `Grizzly.ZWave.Commands.MultiChannelAssociationGroupingsGet`
  * Add `Grizzly.ZWave.Commands.MultiChannelAssociationGroupingsReport`
  * Add `Grizzly.ZWave.Commands.MultiChannelAssociationRemove`
  * Add `Grizzly.ZWave.Commands.MultiChannelAssociationReport`
  * Add `Grizzly.ZWave.Commands.MultiChannelAssociationSet`
  * Add `Grizzly.ZWave.CommandClass.DeviceResetLocally`
  * Add `Grizzly.ZWave.Commands.DeviceResetLocallyNotification`
  * Add `Grizzly.ZWave.Commands.LearnModeSet`
  * Add `Grizzly.ZWave.Commands.LearnModeSetStatus`
  * Add `Grizzly.Inclusions.learn_mode/1`
  * Add `Grizzly.Inclusions.learn_mode_stop/0`
  * Support version 8 of the `Grizzly.ZWave.Commands.AlarmReport`
  * Support parsing naming and location parameters from Z-Wave notifications
  * Add `mix zipgateway.cfg` to print out the zipgateway config that Grizzly
    is configured to use.
  * Add `Grizzly.list_commands/0` to list all support Z-Wave commands in
    Grizzly.
  * Add `Grizzly.commands_for_command_class/1` for listing the Z-Wave commands
    support by Grizzly for a particular command class.
  * Add `:handlers` to `:grizzly` configuration options for firmware update and
    inclusion handlers.
  * Documentation updates

Fixes
  * Parsing the wrong byte for into the wrong notification type
  * Invalid type spec for `Grizzly.ZWave.Security.failed_type_from_byte/1`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.11.0

Grizzly now supports parsing alarm/notification parameters as a keyword list of
parameters. This change is breaking because the event parameters use to be the
raw binary we received from the Z-Wave network and now it is a keyword list.

We only support lock and keypad event parameters currently, but this puts into
place the start of being able to support event parameters.

Enhancements
  * Support parsing event parameters for lock and keypad operations

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.10.3

Enhancements
  * Add `handle_timeout/2` to the `Grizzly.InclusionHandler` behaviour. This
    allows for handling when an inclusion process timesout.
  * Add `Grizzly.Inclusions.stop/0` force stop any type of inclusion process.
  * Add `Grizzly.FirmwareUpdates` module for updating the Z-Wave firmware on
    Z-Wave hardware

Fixes
  * not parsing command classes correctly on `Grizzly.ZWave.Commands.NodeAddStatus`
  * Not stopping an inclusion process correctly when calling
    `Grizzly.Inclusions.add_node_stop/0`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v.0.10.2

Enhancements
  * Add `Grizzly.ZWave.Commands.FailedNodeRemove`
  * Add `Grizzly.ZWave.Commands.FailedNodeRemoveStatus`

Fixes
  * Sensor types returned from the support sensors report
  * Broken link in docs

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v.0.10.1

Enhancements
  * Add `Grizzly.ZWave.Commands.ConfigurationGet`
  * Add `Grizzly.ZWave.Commands.ConfigurationReport`

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.10.0

Removed the parameter `:secure_command_classes` from
`Grizzly.ZWave.Command.NodeInfoCacheReport`. Also updated the param
`:command_classes` to be a keyword list of the various command classes that
the node can have.

The fields in the keyword list are:
  * `:non_secure_supported`
  * `:non_secure_controlled`
  * `:secure_supported`
  * `:secure_controlled`

If you are using `:secure_command_classes` for checking if the device is
securely added you can update like this:

```elixir

{:ok, node_info} = Grizzly.Node.get_info(10)

Keyword.get(Grizzly.ZWave.Command.param!(node_info, :command_classes), :secure_controlled)
```

Enhancements
  * Add `Grizzly.ZWave.Commands.AssociationGroupCommandListGet`
  * Add `Grizzly.ZWave.Commands.AssociationGroupCommandListReport`
  * Add `Grizzly.ZWave.Commands.AssociationGroupInfoGet`
  * Add `Grizzly.ZWave.Commands.AssociationGroupInfoReport`
  * Add `Grizzly.ZWave.Commands.AssociationGroupNameGet`
  * Add `Grizzly.ZWave.Commands.AssociationGroupNameReport`
  * Add `Grizzly.ZWave.Commands.MultiChannelEndpointGet`
  * Add `Grizzly.ZWave.Commands.MultiChannelEndpointReport`

Fixes
  * Internal command class name discrepancies

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0

The official `v0.9.0` release!

If you trying to upgrade from `v0.8.x` please see [Grizzly v0.8.0 -> v0.9.0](https://gist.github.com/mattludwigs/b172eaae0831f71df5ab53e2d6066081)
guide and follow the Changelog from the initial `v0.9.0-rc.0` release.

Changes from the last `rc` are:

Enhancements
  * Support Erlang 23.0 with Elixir 1.10
  * Dep updates and tooling enhancements

Fixes
  * miss spellings of command names

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0-rc.4

Enhancements
  * Add `Grizzly.ZWave.Commands.FirmwareMDGet`
  * Add `Grizzly.ZWave.Commands.FirmwareUpdateMDRequestGet`
  * Add `Grizzly.ZWave.Commands.FirmwareUpdateMDRequestReport`
  * Add `Grizzly.ZWave.Commands.FirmwareUpdateMDStatusReport`
  * Add `Grizzly.ZWave.Commands.FirmwareUpdateMDReport`
  * Add `Grizzly.ZWave.Commands.FirmwareUpdateActivationSet`
  * Add `Grizzly.ZWave.Commands.FirmwareUpdateActivationReport`
  * Remove some dead code

Fixes
  * When resetting the controller we were not closing the connections to
    the nodes. This caused some error logging in `zipgateway` and also left
    open unused resources. This could cause problems later when reconnecting
    devices to resources that were already in the system.

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0-rc.3

Enhancements
  * Some Z-Wave devices report the wrong value for the switch multilevel
    report so we added support for those values.

Fixes
  * When two processes quickly sent the same command to the same device only
    one process would receive the response

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0-rc.2

Deprecated
  * `Grizzly.Node.get_node_info/1` - use `Grizzly.Node.get_info/1` instead

Added
  * `Grizzly.Node.get_info/1`
  * `Grizzly.ZWave.CommandClasses.Supervision`
  * `Grizzly.ZWave.Commands.SupervisionGet`
  * `Grizzly.ZWave.Commands.SupervisionReport`
  * `Grizzly.ZWave.CommandClasses.SensorBinary`
  * `Grizzly.ZWave.Commands.SensorBinaryGet`
  * `Grizzly.ZWave.Commands.SensorBinaryReport`

Enhancements
  * Support for `DoorLockOperationReport` >= V3 parsing

Fixes
  * Bad parsing of `NodAddStatus` `:failed` value

Thank you to those who contributed to this release:

- Jean-Francois Cloutier

## v0.9.0-rc.1

Breaking Changes
  * `Grizzly.ZWave.IconTypes` removed `icon_type` from the atom values of the
    icon name.
  * `Grizzly.ZWave.DeciveTypes.icon_name()` ->
    `Grizzly.ZWave.DeviceTypes.name()`
  * `Grizzly.ZWave.DeciveTypes.icon_integer()` ->
    `Grizzly.ZWave.DeviceTypes.value()`

Enhancements
  * Doc updates
  * Internal code quality
  * Deps updates
  * Better types around DSKs
  * CI support for elixir versions 1.8, 1.9, and 1.10
  * Support all versions of the meter report
  * Support a low battery report

## v0.9.0-rc.0

For more detailed guide to the breaking changes and how to upgrade please see
our [Grizzly v0.8.0 -> v0.9.0](https://gist.github.com/mattludwigs/b172eaae0831f71df5ab53e2d6066081) guide.

This release presents a simpler API, faster boot time, more robustness in Z-Wave communication,
and resolves all open issues on Grizzly that were reported as bugs.

### Removed APIs

* `Grizzly.Node` struct
* `Grizzly.Conn` module
* `Grizzly.Notifications` module
* `Grizzly.Packet` module
* `Grizzly.close_connection`
* `Grizzly.command_class_versions_known?`
* `Grizzly.update_command_class_versions`
* `Grizzly.start_learn_mode`
* `Grizzly.get_command_class_version`
* `Grizzly.has_command_class`
* `Grizzly.connected?`
* `Grizzly.has_command_class_names`
* `Grizzly.config`
* `Grizzly.Network.busy?`
* `Grizzly.Network.ready?`
* `Grizzly.Network.get_state`
* `Grizzly.Network.set_state`
* `Grizzly.Network.get_node`
* `Grizzly.Node.new`
* `Grizzly.Node.update`
* `Grizzly.Node.put_ip`
* `Grizzly.Node.get_ip`
* `Grizzly.Node.connect`
* `Grizzly.Node.disconnect`
* `Grizzly.Node.make_config`
* `Grizzly.Node.has_command_class?`
* `Grizzly.Node.connected?`
* `Grizzly.Node.command_class_names`
* `Grizzly.Node.update_command_class_versions`
* `Grizzly.Node.get_command_class_version`
* `Grizzly.Node.command_class_version_known?`
* `Grizzly.Node.update_command_class`
* `Grizzly.Node.put_association`
* `Grizzly.Node.get_association_list`
* `Grizzly.Node.configure_association`
* `Grizzly.Node.get_network_information`
* `Grizzly.Node.initialize_command_versions`

### Moved APIs

* `Grizzly.reset_controller` -> `Grizzly.Network.reset_controller`
* `Grizzly.get_nodes` -> `Grizzly.Network.get_node_ids`
* `Grizzly.get_node_info` -> `Grizzly.Node.get_node_info`
* `Grizzly.Notifications.subscribe` -> `Grizzly.subscribe_command` and
  `Grizzly.subscribe_commands`
* `Grizzly.Notifications.unsubscribe` -> `Grizzly.unsubscribe`
* `Grizzly.add_node` -> `Grizzly.Inclusions.add_node`
* `Grizzly.remove_node` -> `Grizzly.Inclusions.remove_node`
* `Grizzly.add_node_stop` -> `Grizzly.Inclusions.add_node_stop`
* `Grizzly.remove_node_stop` -> `Grizzly.Inclusions.remove_node_stop`
* `Grizzly.Client` -> `Grizzly.Transport`
* `Grizzly.Security` -> `Grizzly.ZWave.Security`
* `Grizzly.DSK` -> `Grizzly.ZWave.DSK`
* `Grizzly.Node.add_lifeline_group` -> `Grizzly.Node.set_lifeline_association`

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

* Enhancements
  * Make Z-Wave versions standard version formatting
* Fixes
  * Paring the FirmwareMD report for version 5
  * Fix spec for queued commands

## v0.8.7

* Enhancements
  * Support `FIRMWARE_UPDATE_MD` meta data report command v5

## v0.8.6

* Fixes
  * duplicate fields on the `Grizzly.Node` struct

## v0.8.5

* Fixes
  * various spelling and documentation fixes
  * dialzyer fixes

## v0.8.4

* Fixes
  * Handle when there are no nodes in the node provisioning list when
    requesting all the DSKs.

## v0.8.3

* Enhancements
  * Support Wake Up v2 and Multi Channel Association v3

## v0.8.2

* Enhancements
  * Support SWITCH_BINARY_REPORT version 2

## v0.8.1

* Enhancements
  * Update docs and resources
* Fixes
  * An issue when the unsolicited message server would cause a
    no match error that propagated up the supervision tree

Thank you to those who contributed to this release:

* Ryan Winchester

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

* Enhancements
  * Full support for SmartStart meta extensions
  * Add `meta_extensions` field to `Grizzly.CommandClass.NodeProvisioning`
    commands that can handle meta extensions
  * Update `Grizzly.Conn.Server.Config` docs
* Fixes
  * Invalid keep alive (heart beat) interval
  * Set correct constraints on `Time` command offset values

Thank you to those who contributed to this release:

* Jean-Francois Cloutier
* Ryan Winchester

## v0.7.0

Introduces SmartStart support!

SmartStart will allow you to pair a device to a Z-Wave controller with out
turning the device on. Devices that support SmartStart will have a device
specific key (DSK) that you can provide to the controller prior to turning on
the device.

```
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

* Enhancements
  * SmartStart support through the `NodeProvisioning` command class
  * Added `home_id` field to `Grizzly.Node.t()`
  * Support fetching `home_id` of the Z-Wave nodes when fetching
    Z-Wave information about the node

## v0.6.6

* Fixes
  * Application start failure when providing the correct
    data structure to the `zipgateway_cfg` configuration
    field

## v0.6.5

* Enhancements
  * Support `GetDSK` command
  * Support `FailedNodeRemove` command
  * Allow `zipgateway_path` configuration
  * Generate the `zipgateway.cfg` to allow device specific
    information to be passed into the `zipgateway` runtime.

## v0.6.4

* Enhancements
  * Validation of UserCode arguments to help ensure usage of Grizzly
    follows the Z-Wave specification

## v0.6.3

* Enhancements
  * Supports AssociationGroupInformation Command Class

## v0.6.2

* Enhancements
  * Remove the dependence on `pidof` allowing `grizzly` to work on any nerves
    device without the need of `busybox`

### v0.6.1

* Enhancements
  * Update commands `IntervalGet` and `ManufacturerSpecificGet` to be more
    consistent
  * Better handling of invalid `ManufacturerSpecific` info received from
    devices

### v0.6.0

Changed `Grizzly.CommandClass.CommandClassVersion` to `Grizzly.CommandClass.Version`
and changed `Grizzly.ComamndClass.CommandClassVersion.Get` to
`Grizzly.CommandClass.Version.CommandClassGet` as these names reflect the Z-Wave
specification better.

If you only have used `Grizzly.get_command_class_version/2` and the related function
in `Grizzly.Node` module this change should not effect you.

* Enhancements
  * Add support for:
    * MultiChannelAssociation Command Class
    * WakeUp Command Class NoMoreInformation command
    * Complete Association Command Class
    * ZwaveplusInfo Command Class
    * Version Get Command
  * Clean up docs
  * Renamed `Grizzly.CommandClass.CommandClassVersion` to `Grizzly.CommandClass.Version`
  * Renamed `Grizzly.CommandClass.CommandClassVersion.Get` to
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

* Enhancements
  * Provide command argument validation and error handling via
    `Grizzly.Command.EncodeError.()`
  * Update all the command arg encoder/decoder to use tagged
    tuples for better handling of invalid command arguments
  * Introduces new `Grizzly.Command.Encoding` modules for helping
    validate command arugment specifications
* Fixes
  * Crashes when providing invalid command arguments

### v0.4.3

* Enhancements
  * Support Powerlevel command class
  * Doc clean up
  * `Grizzly.send_command/2` and `Grizzly.send_command/3`
    can be passed a node id instead of a node.

### v0.4.2

* Enhancements
  * Support NoOperation command class

### v0.4.1

* Enhancements
  * Add support for Network Management Installation Maintenance
  * Updates to docs and examples

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

* Enhancements
  * Implement multilevel sensor command to get supported sensor types

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

* Enhancements
  * Support `Grizzly.CommandClass.Time` command class
  * Support `Grizzly.CommandClass.TimeParameters` `GET` and `SET` commands
  * Support `Grizzly.CommandClass.ScheduleEntryLock` command class
  * `Grizzly.Notifications.subscribe_all/1` - subscribe to many notifications at once
  * `Grizzly.CommandClass.name/1` - get the name of the command class
  * `Grizzly.CommandClass.version/1` - get the version of the command class
  * `Grizzly.Network.get_nodes/0` - get the nodes on the network
  * `Grizzly.Network.get_node/1` - get a node by node id from the network
  * `Grizzly.Network.get_node_info/1` - get node information about a node via node id
  * `Grizzly.Node.get_ip/1` - can now take either a `Node.t()` or a node id
* Updates
  * Docs and type clean up
* Fixes
  * Timeout when getting command class versions

## v0.2.1

* Updates
  * Support for the time command class
* Fixes
  * Time-boxing of getting a command class version

## v0.2.0

* Fixes
  * Logging with old `ZipGateway` label is now `Grizzly`
  * Fix queued API from `{ZipGateway, :queued_response, ref, response}`
    to `{Grizzly, :queued_response, ref, response}`
  * Fix timeout error when waiting for DTLS server from the
    `zipgateway` side
