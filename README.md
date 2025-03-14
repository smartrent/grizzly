# Grizzly [![CircleCI](https://circleci.com/gh/smartrent/grizzly.svg?style=svg)](https://circleci.com/gh/smartrent/grizzly) [![Hex.pm](https://img.shields.io/hexpm/v/grizzly?style=flat-square)](https://hex.pm/packages/grizzly)

An Elixir library for Z-Wave.

## Installation

```elixir
def deps do
  [
    {:grizzly, "~> 5.2"}
  ]
end
```

## Hardware Requirements

- Z-Wave Bridge Controller
  - [Z-Wave 500](https://www.digikey.com/products/en?mpart=ACC-UZB3-U-BRG&v=336)
  - [Z-Wave 700](https://www.digikey.com/product-detail/en/silicon-labs/SLUSB001A/336-5899-ND/9867108)
- Compatible System
  - [Nerves Compatible System](https://hexdocs.pm/nerves/targets.html#content)
  - [zipgateway-env](https://github.com/mattludwigs/zipgateway-env)
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
for these reports using one of the following functions:

- `Grizzly.subscribe_command/1`
- `Grizzly.subscribe_commands/1`
- `Grizzly.subscribe_node/1`
- `Grizzly.subscribe_nodes/1`

```elixir
Grizzly.subscribe_command(:door_lock_operation_report)

# manually unlock a lock

flush

{:grizzly, :report, %Grizzly.Report{type: :unsolicited}}
```

To know what reports a device sends please see the device's user manual as these
events will be outlined by the manufacture in the manual.

## Supported Command Classes

| Command Class                   | Version | Notes                              |
|---------------------------------|--------:|------------------------------------|
| Alarm (Notification)            |       8 |                                    |
| Anti-theft                      |       3 |                                    |
| Anti-theft Unlock               |       1 |                                    |
| Application Status              |       1 |                                    |
| Association                     |       3 |                                    |
| Association Group Info          |       3 |                                    |
| Barrier Operator                |       1 |                                    |
| Basic                           |       2 |                                    |
| Battery                         |       3 |                                    |
| Binary Sensor                   |      2* | Partial support, obsoleted by spec |
| Binary Switch                   |       2 |                                    |
| Central Scene                   |       3 |                                    |
| Clock                           |       1 |                                    |
| Configuration                   |       4 |                                    |
| CRC-16 Encapsulation            |       1 |                                    |
| Device Reset Locally            |       1 |                                    |
| Door Lock                       |       4 |                                    |
| Firmware Update MD              |       7 |                                    |
| Hail                            |       1 |                                    |
| Indicator                       |       4 |                                    |
| Mailbox                         |       2 |                                    |
| Manufacturer-specific           |       2 |                                    |
| Meter                           |       1 |                                    |
| Multi-channel                   |       4 |                                    |
| Multi-channel association       |       4 |                                    |
| Multi-command                   |       1 |                                    |
| Multilevel Sensor               |     11* | Partial support                    |
| Multilevel Switch               |       4 |                                    |
| NM Basic Node                   |       2 |                                    |
| NM Inclusion                    |       4 |                                    |
| NM Installation and Maintenance |       4 |                                    |
| NM Proxy                        |      3* | Partial support for v4             |
| No Operation                    |       1 |                                    |
| Node Naming and Location        |       1 |                                    |
| Node Provisioning               |       1 |                                    |
| Powerlevel                      |       1 |                                    |
| Scene Activation                |       1 |                                    |
| Scene Actuator Configuration    |       1 |                                    |
| Schedule Entry Lock             |       3 |                                    |
| Security                        |      1* | Partial support                    |
| Security 2                      |      1* | Partial support                    |
| Sound Switch                    |       2 |                                    |
| Supervision                     |       2 |                                    |
| Thermostat Fan Mode             |       1 |                                    |
| Thermostat Fan State            |       2 |                                    |
| Thermostat Mode                 |       2 |                                    |
| Thermostat Operating State      |       1 |                                    |
| Thermostat Setback              |       1 |                                    |
| Thermostat Setpoint             |      3* | Partial support                    |
| Time Parameters                 |       1 |                                    |
| Time                            |       2 |                                    |
| User Code                       |       2 |                                    |
| Version                         |       3 |                                    |
| Wake Up                         |       3 |                                    |
| Window Covering                 |       1 |                                    |
| Z/IP Gateway                    |      1* | Partial support                    |
| Z/IP                            |       5 |                                    |
| Z-Wave Plus Info                |       2 |                                    |

## Get Started

### Quick and Fast running locally

If you want to run Grizzly locally for development and/or learning before going
through the challenge of compiling and running in Nerves we recommend the
[zipgateway-env](https://github.com/mattludwigs/zipgateway-env) project. This
provides a docker container and CLI for compiling and running different
versions of `zipgateway`.

### Nerves Devices (WIP)

First download the [Z/IP GW
SDK](https://www.silabs.com/products/development-tools/software/z-wave/controller-sdk/z-ip-gateway-sdk)
from Silicon Labs. You'll need to create an account with them to do this, but
the download is free.

The default binaries that come with the download will not work by default in
Nerves system, so you will need to compile the source for your target. The
source code can be found in the `Source` directory.

This can be tricky and the instructions are a work in progress, so for now
please contact us if you any troubles.

### Connecting zipgateway to Grizzly

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

Supported configuration fields are documented in `t:Grizzly.Supervisor.arg/0`.

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

## Virtual devices

Grizzly provides a way to work with virtual devices. These devices should work
as their hardware counterparts, however, the state of these devices are held in
memory.

Grizzly provides to example virtual devices:

1. `Grizzly.VirtualDevices.Thermostat`
1. `Grizzly.VirtualDevices.TemperatureSensor`

To use These virtual devices you will have to start them using the
`start_link/1` call. These are not supervised by Grizzly, so you will need to
add them to your supervision tree. The reason for this is to provide the maximum
flexibility to the consumer application in terms of how processes are started
and supervised.

After starting the device you can call the `Grizzly.send_command/4` function to
send the device a command.

```elixir
{:ok, _pid} = Grizzly.VirtualDevices.Thermostat.start_link([])
{:ok, [{:virtual, _id} = virtual_device_id]} = Grizzly.Network.get_all_node_ids()

Grizzly.send_command(virtual_device_id, :thermostat_setpoint_get)
```

Virtual device ids are tuples where the first item is the atom `:virtual` and
the second item an integer of the device id, for example:
`{:virtual, device_id}`. Grizzly provides a guard and a helper function for any
checking you might have to do:

1. `Grizzly.is_virtual_device/1` (guard)
1. `Grizzly.virtual_device?/1` (function)

Also, the documentation for functions in `Grizzly.Node` and `Grizzly.Network`
should indicate if they work with virtual devices.

## Resources

- [Z-Wave Specification Documentation](https://www.silabs.com/products/wireless/mesh-networking/z-wave/specification)
- [Z-Wave Learning Resources](https://www.silabs.com/products/wireless/learning-center/mesh-networking/z-wave)
- [Specific Z-Wave product information](https://products.z-wavealliance.org/regions)
