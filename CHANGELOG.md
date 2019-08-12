## Changelog

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

