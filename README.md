# 🐻 Grizzly

[![CircleCI](https://circleci.com/gh/smartrent/grizzly.svg?style=svg)](https://circleci.com/gh/smartrent/grizzly)

An Elixir library for Z-Wave

## Installation

```elixir
def deps do
  [
    {:grizzly, "~> 0.4", organization: "smartrent"}
  ]
end
```

## Requirements

- [Z-Wave Bridge Controller](https://www.digikey.com/products/en?mpart=ACC-UZB3-U-BRG&v=336)
- [Nerves Compatible System](https://hexdocs.pm/nerves/targets.html#content)
- [Silicon Labs zipgateway binary](https://www.silabs.com/products/development-tools/software/z-wave/controller-sdk/z-ip-gateway-sdk)

You will need to need to be able to compile the `zipgateway` binary for the target
system. This can be really hard, so please contact us for help.

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

If you are using `s2_unauthenticated` this is call you will want to make:

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

Addtional Z-Wave docs can be found at [Silicon Labs](https://www.silabs.com/products/development-tools/software/z-wave/controller-sdk/z-ip-gateway-sdk).

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

see the `Grizzly` module docs for more details about `Grizzly.send_command`

## Configuration

Different systems will use different serial ports to talk to the Z-Wave controller.
In order to configure this, there is a `serial_port` option. Below is an example
for the Raspberry PI 3:

```elixir
config :grizzly,
  serial_port: "/dev/ttyACM0"
```

If you are using a base nerves system please see the documentation for your particular
system at the [Nerves Project](https://github.com/nerves-project) github page.

To run some scripts that `zipgateway` uses we need the `pidof` command line utility. 
Not all Nerves base systems provide this utility so you can use the [busybox](https://hex.pm/packages/busybox)
package to avoid having to build a custom nerves system. After adding the `busybox` package
to your `mix.exs` file, you can configure `Grizzly` to use the busybox path for the `pidof`
utility:

```elixir
config :grizzly,
  pidof_bin: "/srv/erlang/lib/busybox-0.1.2/priv/bin/pidof"
```

Be sure to check the version of the `busybox` package you are using matches
the version in the path.

If you want to run tests without running the `zipgateway` binary provided by Silicon Labs you
can configure `run_zipgateway_bin` to be `false`:

```elixir
config :grizzly,
  run_zipgateway_bin: false
```

