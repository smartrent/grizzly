![Grizzly Logo](assets/grizzly_main-md.png)

[![CircleCI](https://circleci.com/gh/smartrent/grizzly.svg?style=svg)](https://circleci.com/gh/smartrent/grizzly)
[![Hex.pm](https://img.shields.io/hexpm/v/grizzly?style=flat-square)](https://hex.pm/packages/grizzly)

An Elixir library for Z-Wave

## Installation

```elixir
def deps do
  [
    {:grizzly, "~> 0.8"}
  ]
end
```

## Requirements

- [Z-Wave Bridge Controller](https://www.digikey.com/products/en?mpart=ACC-UZB3-U-BRG&v=336)
- [Nerves Compatible System](https://hexdocs.pm/nerves/targets.html#content)
- [Silicon Labs zipgateway binary](https://www.silabs.com/products/development-tools/software/z-wave/controller-sdk/z-ip-gateway-sdk)


See instructions for compiling the `zipgateway` binary.

## Usage

### Adding Z-Wave Devices

When adding Z-Wave devices you will have to know what security group the
device is using. There are 3 groups: none, S0, and S2. For none and S0 you
don't have to do anything special during the inclusion process:

```elixir
iex> Grizzly.add_node()
iex> flush
{:node_added, %Grizzly.Node{...}}
```

After calling `Grizzly.add_node/0` you will then trigger the pairing process
on the device, the instructions for that process can be found in the device's
user manual.

However, if your device is using S2 security you will need to use `Grizzly.add_node/1`.

If you are using `s2_unauthenticated` this is the call you will want to make:

```elixir
iex> Grizzly.add_node(s2_keys: [:s2_unauthenticated])
iex> flush
```

If you are using `s2_authenticated` you will need to provide a pin that
is located on the device:

```elixir
iex> Grizzly.add_node(s2_keys: [:s2_authenticated], pin: 1111)
iex> flush
```

You will see some additional messages when flushing when using S2 security
but you will not need to do anything with them. When using a `GenServer` to
manage inclusion you can handle messages via `handle_info/2`

See `Grizzly.Inclusion` module for more information about adding Z-Wave devices
to the network.

### Removing a Z-Wave Device

Removing a Z-Wave device looks like:

```elixir
iex> Grizzly.remove_node()
iex> flush
{:node_removed, 12}
```

Where `12` is the id of the node you removed.

When you use a `GenServer` to manage exclusion you can handle messages via
`handle_info/2`

See `Grizzly.Inclusion` module for more information about removing Z-Wave devices
from the network.

Additional Z-Wave docs can be found at [Silicon Labs](https://www.silabs.com/products/development-tools/software/z-wave/controller-sdk/z-ip-gateway-sdk).

### Controlling a Z-Wave Device

Say you have added a door lock to your Z-Wave controller that has the id of `12`, now
you want to unlock it. There are three steps to this process: get the node from the
Z-Wave network, connect to the node, and then send Z-Wave commands to it.

```elixir
iex> {:ok, lock} = Grizzly.get_node(12)
iex> {:ok, lock} = Grizzly.Node.connect(lock)
iex> Grizzly.send_command(lock, Grizzly.CommandClass.DoorLock.OperationSet, mode: :unsecured)
:ok
```

If you are just trying things out in an iex session can you use `send_command`
with the node id:

```elixir
iex> Grizzly.send_command(12, Grizzly.CommandClass.DoorLock.OperationSet, mode: :unsecured)
```

However, this is slower in general and is only recommended for quick one off
command sending. If you're building a long running application the first
example is recommended along with storing the connected device to keep the
connection alive for faster response times.

See the `Grizzly` module docs for more details about `Grizzly.send_command`

### Handling Z-Wave Notifications

Grizzly has a pubsub module (`Grizzly.Notifications`) which is used for sending
or receiving notifications.

You can subscribe to notifications using:

```elixir
Grizzly.Notifications.subscribe(topic)
```

or

```elixir
Grizzly.Notifications.subscribe_all(topic_list)
```

See [`Grizzly.Notifications`](https://hexdocs.pm/grizzly/Grizzly.Notifications.html)
docs for more info.

## Z-Wave Bridge Configuration

Grizzly defers the low-level Z-Wave protocol handling to a combination of third
party software and hardware. The software is silicon Labs' `zipgateway` and the
hardware is a Silicon Labs Z-Wave bridge.

This has a major advantage over using a regular Z-Wave stick such as the Aeon
product: the Silicon Labs bridge contains the proprietary Z-Wave stack that
properly handles the different security levels required by devices such as door
locks. This makes Grizzly more responsive and reliable.

### Configure the Z-Wave Bridge

Different systems will use different serial ports to talk to the Z-Wave
bridge. In order to configure this, there is a `serial_port` option. Below
is an example for the Raspberry PI 3:

```elixir
config :grizzly,
  serial_port: "/dev/ttyACM0"
```

If you are using a base nerves system please see the documentation for your
particular system at the [Nerves Project](https://github.com/nerves-project)
github page.


### Compile and Configure zipgateway

First download the [Z/IP GW
SDK](https://www.silabs.com/products/development-tools/software/z-wave/controller-sdk/z-ip-gateway-sdk)
from Silicon Labs. You'll need to create an account with them to do this, but
the download is free.

The default binaries that come with the download will not work by default in
Nerves system, so you will need to compile the source for your target. The
source code can be found in the `Source` directory.

This can be tricky and the instructions are a work in progress, so for now
please contact us if you any troubles.

#### Connecting zipgateway to Grizzly

`zipgateway` runs as a separate server, accessed over a DTLS (UDP over SSL)
connection. Grizzly will automatically start this server. It assumes the
executable is in `/usr/sbin/zipgateway`. If this is not the case, you can
specify the actual location with

```elixir
config :grizzly,
  zipgateway_path: "«path»"
```

Grizzly uses the `taptun` module to manage the TCP connection: it checks that
this is loaded as it starts.

If you want to run tests without running the `zipgateway` binary provided by Silicon Labs you
can configure `run_zipgateway_bin` to be `false`:


```elixir
config :grizzly,
  run_zipgateway_bin: false
```

#### Configuring zipgateway

The `zipgateway` binary is passed a configuration file named `zipgateway.cfg`.
This has configuration parameters around networking and setting device specific
information. Most of these configuration settings are static, so Grizzly can
handle those for you in a reliable way. However, there are few exposed
configuration options to allow some customization around device specific
information, logging, and network interface set up.

Supported configuration fields are:

* `:tun_script` - a path to the `.tun` script (default priv dir of Grizzly)
* `:manufacturer_id`: Id to set in the version report (default `0`)
* `:hardware_version` - Hardware version to set in the version report (default `1`)
* `:product_id` - Id to set in the version report (default `1`)
* `:product_type` - Id to set in the version report (default `1`)
* `:serial_log` - Log file for serial communication. Used for debugging. If this
   option is not set the no logging is done (default none)

For the most part if you are using Grizzly to run zipgateway the defaults should
just work.

When going through certification you will need provide some device specific
information:

```elixir
config :grizzly,
  zipgateway_cfg: %{
    manufacturer_id: 0,
    product_type: 1,
    product_id: 1,
    hardware_version: 1
  }
```

The `manufacturer_id` will be given to you by Silicon Labs, and will default
to `0`if not set (this is `zipgateway` level default).

The above fields have no impact on the Grizzly runtime, and are only useful for
certification processes.

When running `zipgateway` binary out side of Grizzly this configuration field is ignored
and you will need to pass in the location to your configuration like so:

`zipgateway -c /path/to/zipgateway.cfg`

## Resources

* [Z-Wave Specification Documentation](https://www.silabs.com/products/wireless/mesh-networking/z-wave/specification)
* [Z-Wave Learning Resources](https://www.silabs.com/products/wireless/learning-center/mesh-networking/z-wave)
