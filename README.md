![Grizzly Logo](assets/grizzly_main-md.png)

[![CircleCI](https://circleci.com/gh/smartrent/grizzly.svg?style=svg)](https://circleci.com/gh/smartrent/grizzly)
[![Hex.pm](https://img.shields.io/hexpm/v/grizzly?style=flat-square)](https://hex.pm/packages/grizzly)

An Elixir library for Z-Wave

## Installation

```elixir
def deps do
  [
    {:grizzly, "~> 0.9.0-rc.2"}
  ]
end
```

## Hardware Requirements

- Z-Wave Bridge Controller
    * [Z-Wave 500](https://www.digikey.com/products/en?mpart=ACC-UZB3-U-BRG&v=336)
    * [Z-Wave 700](https://www.digikey.com/product-detail/en/silicon-labs/SLUSB001A/336-5899-ND/9867108)
- [Nerves Compatible System](https://hexdocs.pm/nerves/targets.html#content)
- [Silicon Labs zipgateway binary](https://www.silabs.com/products/development-tools/software/z-wave/controller-sdk/z-ip-gateway-sdk)

The `zipgateway` binary allows Grizzly to use Z-Wave over IP or Z/IP. Using the
`zipgateway` binary provided by Silicon labs allows Grizzly to support the full
range of Z-Wave features quickly and reliability. Some of the more advanced
features like S2 security and smart start are already supported in Grizzly.

See instructions for compiling the `zipgateway` binary.

## Basic Usage

To use a device you have to add it to the Z-Wave network. This is "called
including a device" or "starting an inclusion." While most of the Grizzly's API
is synchronous the process of adding a node is not. So, if you are working from
the IEx console you can use flush to see the newly add device. Here's how this
process roughly goes.

```elixir
iex> Grizzly.Inclusions.add_node()
:ok
iex> flush
%Grizzly.ZWave.Command{
  name: :node_add_status,
  ....
  params: [<node info in here>]
}
```

To remove a device we have to do an exclusion. Z-Wave uses the umbrella term
"inclusions" for both adding a removing a device, but an "inclusion" is only
about device pairing and "exclusion" is only about device removal. The way to
remove the device from your network in IEx:

```elixir
iex> Grizzly.Inclusions.remove_node()
:ok
iex> flush
%Grizzly.ZWave.Command{
  name: :node_remove_status
  ...
  params: [<information about exclusion>]
}
```

There are more details about this process and how to better tie into the
Grizzly runtime for this events in `Grizzly.Inclusions`.

After you included a node it will be given a node id that you can use to send
Z-Wave commands to it. Say for example we added an on off switch to our
network, in Z-Wave this will be called a binary switch, and it was given the id
of `5`. Turning it off and on would look like this in IEx:

```elixir
iex> Grizzly.send_command(5, :switch_binary_set, target_value: :on
:ok
iex> Grizzly.send_command(5, :switch_binary_set, target_value: :off)
:ok
```

`Grizzly.send_command/3` can return a few responses.

### Successful Commands

1. `:ok` - normally for setting things on a device or changing the device's
   state
1. `{:ok, Grizzly.ZWave.Command.t()}` - this is normally returned when asking
   for a device state or about some information about a device or Z-Wave
   network
1. `{:queued, reference, queue_time}` - some devices sleep, so sending a
   command to it will be queued for some `queue_time`. Once the device wakes
   up and handles the queued command the calling process will receive a message
   like: `{:grizzly, :queued_command_response, reference, response}` where the
   `reference` is the one that was given at the time of the call, and the
   `response` one of the two above responses depending on the command that was
   sent.

### When things go wrong

1. `{:error, :timeout}` - if the command times out for whatever reason
1. `{:error, :nack_response}` - for when the node is not responding to the
    command. Grizzly has automatic retries, so if you got this message that
    might mean the node is reachable, your Z-Wave network is experiencing a of
    traffic, or the node has recently been hit with a lot of commands and
    cannot handle anymore at this moment.

More information about `Grizzly.send_command/3` and the options like timeouts
and retries that can be passed to see the `Grizzly` module.

## Grizzly Runtime

The Grizzly runtime is a [module](https://github.com/smartrent/grizzly/blob/master/lib/grizzly/runtime.ex)
that manages the set up operations of the Z-Wave IP stack.

### Z-Wave is Ready

When the Z-Wave stack is completely set up Grizzly will call the `:on_ready`
module function arg callback that is configured for the runtime. To configure
this add this to your `config.exs` file:

```elixir
config :grizzly,
  runtime: [
    on_ready: {MyModule, :zwave_up, []}
  ]
```

In most cases this all the configuration you need for the runtime.

### Advanced Runtime Configuration

By default the Grizzly runtime handle setting the `zipgateway` binary and
generate the correct configuration files or it to run and network correctly.
The nice things about this default setup is Grizzly leverages OTP to supervise
the `zipgateway` binary, and if the binary crashes Grizzly will restart it.

However, there are use cases for needing to manage the `zipgateway` binary
outside of Grizzly. So if you plan on starting `zipgateway` outside of Grizzly
you can configure the runtime like:

```elixir
config :grizzly,
  runtime: [
    run_zipgateway_bin: false
  ]
```

For more information see `Grizzly.Runtime` module

## Z-Wave Bridge Configuration

Grizzly defers the low-level Z-Wave protocol handling to a combination of third
party software and hardware. The software is silicon Labs' `zipgateway` and the
hardware is a Silicon Labs Z-Wave bridge.

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
* [Specific Z-Wave product information](https://products.z-wavealliance.org/regions)
