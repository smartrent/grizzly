## Changelog

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

