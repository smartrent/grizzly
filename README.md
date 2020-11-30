![Grizzly Logo](assets/grizzly_main-md.png)

[![CircleCI](https://circleci.com/gh/smartrent/grizzly.svg?style=svg)](https://circleci.com/gh/smartrent/grizzly)
[![Hex.pm](https://img.shields.io/hexpm/v/grizzly?style=flat-square)](https://hex.pm/packages/grizzly)

An Elixir library for Z-Wave

## Installation

```elixir
def deps do
  [
    {:grizzly, "~> 0.15.7"}
  ]
end
```

## Hardware Requirements

- Z-Wave Bridge Controller
    * [Z-Wave 500](https://www.digikey.com/products/en?mpart=ACC-UZB3-U-BRG&v=336)
    * [Z-Wave 700](https://www.digikey.com/product-detail/en/silicon-labs/SLUSB001A/336-5899-ND/9867108)
- Compatible System
    * [Nerves Compatible System](https://hexdocs.pm/nerves/targets.html#content)
    * [zipgateway-env](https://github.com/mattludwigs/zipgateway-env)
- [Silicon Labs zipgateway binary](https://www.silabs.com/products/development-tools/software/z-wave/controller-sdk/z-ip-gateway-sdk)

The `zipgateway` binary allows Grizzly to use Z-Wave over IP or Z/IP. Using the
`zipgateway` binary provided by Silicon labs allows Grizzly to support the full
range of Z-Wave features quickly and reliability. Some of the more advanced
features like S2 security and smart start are already supported in Grizzly.

See instructions below for compiling the `zipgateway` binary and/or running locally.

If you want a quick reference to common uses of Grizzly see the `cookbook` docs.

## Basic Usage

Grizzly exposes a supervisor `Grizzly.Supervisor` for the consuming application
to add to its supervisor tree. This gives the most flexibility and control over
when Grizzly's processes start. Common ways to start Grizzly can look like:

```elixir
# all the default options are fine
Grizzly.Supervisor.start_link()

# using custom hardware where the serial port is different than the default
# the default serial port is /dev/ttyUSB0.
Grizzly.Supervisor.start_link(serial_port: "/dev/ttyS4")

# if your system is using zipgateway-env and/or something other than Grizzly
# will start and manage running the zipgateway binary
Grizzly.Supervisor.start_link(run_zipgateway: false)
```

There are other configuration options you can pass to Grizzly but the above are
most common options. The `Grizzly.Supervisor` docs explains all the options in
more detail.

To use a device you have to add it to the Z-Wave network. This is "called
including a device" or "starting an inclusion." While most of the Grizzly's API
is synchronous the process of adding a node is not. So, if you are working from
the IEx console you can use flush to see the newly add device. Here's how this
process roughly goes.

```elixir
iex> Grizzly.Inclusions.add_node()
:ok
iex> flush
{:grizzly, :report,  %Grizzly.Report{
  command: %Grizzly.ZWave.Command{
    name: :node_add_status,
    params: [<node info in here>]
  }
}}
```

To remove a device we have to do an exclusion. Z-Wave uses the umbrella term
"inclusions" for both adding a removing a device, but an "inclusion" is only
about device pairing and "exclusion" is only about device removal. The way to
remove the device from your network in IEx:

```elixir
iex> Grizzly.Inclusions.remove_node()
:ok
iex> flush
{:grizzly, :report,  %Grizzly.Report{
  command: %Grizzly.ZWave.Command{
    name: :node_remove_status,
    params: [<node info in here>]
  }
}}
```

There are more details about this process and how to better tie into the
Grizzly runtime for this events in `Grizzly.Inclusions`.

After you included a node it will be given a node id that you can use to send
Z-Wave commands to it. Say for example we added an on off switch to our
network, in Z-Wave this will be called a binary switch, and it was given the id
of `5`. Turning it off and on would look like this in IEx:

```elixir
iex> Grizzly.send_command(5, :switch_binary_set, target_value: :on)
{:ok, %Grizzly.Report{}}
iex> Grizzly.send_command(5, :switch_binary_set, target_value: :off)
{:ok, %Grizzly.Report{}}
```

For more documentation on what `Grizzly.send_command/4` can return see the
`Grizzly` and `Grizzly.Report` module documentation.

### Successful Commands

1. `{:ok, %Grizzly.Report{type: :ack_response}}` - normally for setting things
   on a device or changing the device's state
1. `{:ok, %Grizzly.Report{type: :command}}` - this is normally returned when asking
   for a device state or about some information about a device or Z-Wave
   network. The command be access by the `:command` field field of the report.
1. `{:ok, %Grizzly.Report{type: :queued}}` - some devices sleep, so sending a
   command to it will be queued for some amount of type that can be access in
   the `:queued_delay` field. Once a device wakes up the calling process will
   receive the messages in this form: `{:grizzly, :report, %Grizzly.Report{}}`
   where the type can either be `:queued_ping` or `:command`. To check if the
   report you receive was queued you can check the `:queued` field in the
   report.
1. `{:ok, %Grizzly.Report{type: :timeout}}` - the command was sent but for some
   reason this commanded timed out.

### When things go wrong

1. `{:error, :nack_response}` - for when the node is not responding to the
    command. Grizzly has automatic retries, so if you got this message that
    might mean the node is reachable, your Z-Wave network is experiencing a of
    traffic, or the node has recently been hit with a lot of commands and
    cannot handle anymore at this moment.
1. `{:error, :including}` - the Z-Wave controller is currently in the inclusion
   state and the controller cannot send any commands currently
1. `{:error, :firmware_updating}` - the Z-Wave controller is currently in the
   process of having it's firmware updated and is not able to send commands

More information about `Grizzly.send_command/4` and the options like timeouts
and retries that can be passed to see the `Grizzly` module.

More information about reports see the documentation in the `Grizzly.Report`
module.

## Unsolicited Messages

When reports are sent from the Z-Wave network to the controller without the
controller asking for a report these are called unsolicited messages. A concrete
example of this is when you manually unlock a lock, the controller will receive
a message from the device if the associations are setup correctly (see
`Grizzly.Node.set_lifeline_association/2` for more information). You can listen
for these reports using either `Grizzly.subscribe_command/1` or
`Grizzly.subscribe_commands/1`.

```elixir
Grizzly.subscribe_command(:door_lock_operation_report)

# manually unlock a lock

flush

{:grizzly, :report, %Grizzly.Report{type: :unsolicited}}
```

To know what reports a device sends please see the device's user manual as these
events will be outlined by the manufacture in the manual.

### Compile and Configure zipgateway

## Quick and Fast running locally

If you want to run Grizzly locally for development and/or learning before going
through the challenge of compiling and running in Nerves we recommend the
[zipgateway-env](https://github.com/mattludwigs/zipgateway-env) project. This
provides a docker container and CLI for compiling and running different
versions of `zipgateway`.

## Nerves Devices (WIP)

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
