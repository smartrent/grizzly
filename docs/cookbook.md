# Grizzly Cookbook

Below are short notes about using Grizzly.

1. [Starting Grizzly](#starting-grizzly)
1. [Docker Local Development](#docker-local-development)
1. [Add Devices](#add-devices)
1. [Remove Devices](#remove-devices)
1. [Factory Reset Controller](#factory-reset-controller)
1. [Command Basics](#command-basics)
1. [Binary Switches](#binary-switches)
1. [Door Locks](#door-locks)
1. [DSK](#dsk)
1. [Indicator Light](#indicator-light)
1. [Firmware Information](#firmware-information)

## Starting Grizzly

If you using Grizzly you will need to start the supervision tree manually.

```elixir
Grizzly.Supervisor.start_link(opts)
```

or add the supervisor to your supervision tree:

```elixir
children = [
    ... other processes ...
    {Grizzly.Supervisor, grizzly_opts},
    ... other processes ...
]

Supervisor.init(children, supervisor_opts)
```

## Docker Local Development

Getting the `zipgateway` binary compiled and running can be hard. Due to
licenses we cannot redistribute a pre-compiled version either. However, the
[zipgateway-env](https://github.com/mattludwigs/zipgateway-env) project has is
a docker based environment that is setup to compile `zipgateway` from source and
provides a CLI for running the binary.

After getting `zipgateway-env` setup and working you can use grizzly locally.
You will need to pass the `:run_zipgateway` option when you start Grizzly
setting it to `false`:

```elixir
iex> Grizzly.Supervisor.start_link(run_zipgateway: false)
```

```elixir
children = [
    ... other processes ...
    {Grizzly.Supervisor, [run_zipgateway: false]},
    ... other processes ...
]

Supervisor.init(children, supervisor_opts)
```

## Add Devices

There are 3 security schemas a device can be included with:

1. [No Security](#no-security)
1. [S0](#s0)
1. [S2]

When adding a device you will need to put the device into inclusion mode. How to
do this is normally found in the device's user manual. So, be sure to read that
to learn how to add the device to the Z-Wave network.

Also, you will need to put the controller into inclusion mode:

```elixir
Grizzly.Inclusions.add_node()
```

After an inclusion is done the calling process will receive this message:

`{:grizzly, :report, %Grizzly.Report{}}`

Where the `Grizzly.Report` will have the command field contain the
[NodeAddStatus](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.NodeAddStatus.html)
command.

That command's param `:status` will tell you if inclusion failed or not:

``` elixir
alias Grizzly.ZWave.Command

#... code ...

def handle_info({:grizzly, :report, report}, state) do
  case report.command.name do
    :node_add_status ->
      handle_node_add_status(report.command, state)
  end
end

defp handle_node_status(command, state) do
  case Command.param!(command, :status) do
    :done -> Logger.info("YAY!")
    :failed -> Logger.info("Sad!")
  end

  {:noreply, state}
end
```

If you want to check the security schema that was used you can check the
`NodeAddStatus` command param `:granted_keys`:

```elixir
def get_security(node_add_status_command) do
  node_add_status_command
  |> Command.param!(:granted_keys)
  |> Grizzly.ZWave.Security.get_highest_level()
end
```

### No Security

No security is done in these 3 steps

1. Put the controller in inclusion mode
1. Put the device in inclusion mode
1. Wait until `NodeAddStatus` command is received

### S0

S0 inclusion is done the same way as [No Security](#no-security). The only
difference the `:granted_keys` param will be `[:s0]`.

## Remove Devices

To remove a device you can call:

```elixir
Grizzly.Inclusions.remove_device()
```

By default you will get a message sent to the calling process that looks like:

`{:grizzly, :report, %Grizzly.Report{}}`

Where the report command that is received is
`Grizzly.ZWave.Commands.NodeRemoveStatus`.

You can also provide an Inclusion handler which is explained in [Add Devices](#add-devices).

## Factory Reset Controller

If you have been doing development and adding and removing devices or testing
some Z-Wave Network functionally that has lead to the network getting in a
broken state and you just want to start over again you can reset your controller
by doing this:

```elixir
Grizzly.Network.reset_controller()
```

This will make the controller forget any devices that are paired with it and
delete all node provisioning entries from the SmartStart node provisioning list.

For devices that thought they were included on the newly reset controller you
will to excluded them by going through the [remove devices](#remove-devices)
steps before you are able to re-include them back into the controller's
network.

## Command Basics

In Z-Wave everything that is sent and received is a command. The controller
will send commands to a device and the device will send commands back. However,
there is lifecycle these command go through within Grizzly so the abstraction
Grizzly presents is you send a command and receive a report.

The reason for a report is because normally when you send a command and the
device answers to that command it will send a command who's name normally ends
with `Report`.

### When you get command reports back

The most common case you get a command report back is when you send a `GET`
based command. That is you want to read some value from the device. Common
commands that expect a report are:

1. [Grizzly.ZWave.Commands.SwitchBinaryGet](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.SwitchBinaryGet.html)
1. [Grizzly.ZWave.Commands.DoorLockOperationGet](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.DoorLockOperationGet.html)
1. [Grizzly.ZWave.Commands.UserCodesGet](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.UserCodeGet.html)
1. [Grizzly.ZWave.Commands.ThermostatSetpointGet](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.ThermostatSetpointGet.html)

Just to highlight a few.

There is common pattern here: If the command name ends with `Get` it probably
will receive a report command back.

### When you get ack responses back

The other main report you will receive is an `:ack_response`. This report just
says the communication to the device was successful. That does not mean the
device will perform what you sent, but that is was received. This is common when
you want to set a value on the device.

Commands ending with `Set` will normally be these commands.

But the `Get` and the `Set` commands can have exceptions to the normal so please
read the module documentation for the command your are using.

## Binary Switches

Binary switches are your basic on-off switch. Z-Wave commands to control these
are:

Commands:

1. [Grizzly.ZWave.Commands.SwitchBinaryGet](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.SwitchBinaryGet.html)
1. [Grizzly.ZWave.Commands.SwitchBinarySet](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.SwitchBinarySet.html)

Report:

1. [Grizzly.ZWave.Commands.SwitchBinaryReport](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.SwitchBinaryReport.html)

Usage:

```elixir
iex> {ok, report} = Grizzly.send_command(switch_id, :switch_binary_get)
iex> Command.param!(report.command, :target_value)
:on
```

```elixir
iex> {:ok, %Grizzly.Report{type: :ack_response}} =
       Grizzly.send_command(switch_id, :switch_binary_set, value: :off)
{:ok, %Grizzly.Report{}}
```

## Door Locks

Commands:

1. [Grizzly.ZWave.Commands.DockLockOperationGet](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.DoorLockOperationGet.html)
1. [Grizzly.ZWave.Commands.DockLockOperationSet](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.DoorLockOperationSet.html)

Reports:

1. [Grizzly.ZWave.Commands.DockLockOperationReport](https://hexdocs.pm/grizzly/Grizzly.ZWave.Commands.DoorLockOperationReport.html)

Usage:

```elixir
iex> {:ok, report} = Grizzly.send_command(lock_id, :door_lock_operation_get)
iex> Command.param!(report.command, :mode)
:secured
```

```elixir
iex> {:ok, %Grizzly.Report{type: :ack_response}} =
       Grizzly.send_command(lock_id, :dock_lock_operation_set, mode: :unsecured)
{:ok, %Grizzly.Report{}}
```

## DSK

This returns this node's DSK. This is normally printed on a label as a QRCode or
a UUID and is what will show up on a hub if you include this node into a Z-Wave
network.

```elixir
iex> Grizzly.Node.get_dsk(1, :learn)
{:ok,
 %Grizzly.Report{
   command: %Grizzly.ZWave.Command{
     command_byte: 9,
     command_class: Grizzly.ZWave.CommandClasses.NetworkManagementBasicNode,
     impl: Grizzly.ZWave.Commands.DSKReport,
     name: :dsk_report,
     params: [
       seq_number: 58,
       add_mode: :learn,
       dsk: "12345-12345-12345-12345-12345-12345-12345-12345"
     ]
   },
   command_ref: #Reference<0.2080011265.2613837825.149583>,
   node_id: 1,
   queued: false,
   queued_delay: 0,
   status: :complete,
   transmission_stats: [],
   type: :command
 }}
```

## Indicator Light

Z-Wave requires that devices be able to identify themselves. Here's how to test
this:

```elixir
# Turn the indicator on
iex> Grizzly.send_command(1, :indicator_set,
       resources: [
         [indicator_id: :node_identify, property_id: :toggling_periods, value: 1],
         [indicator_id: :node_identify, property_id: :toggling_cycles, value: 1]
       ]
     )

# Turn off
iex> Grizzly.send_command(1, :indicator_set,
       resources: [
         [indicator_id: :node_identify, property_id: :toggling_periods, value: 0],
         [indicator_id: :node_identify, property_id: :toggling_cycles, value: 0]
       ]
     )
```

## Firmware Information

To check firmware version information

```elixir
iex> Grizzly.send_command(node_id, :version_get)
{:ok,
 %Grizzly.Report{
   command: %Grizzly.ZWave.Command{
     command_byte: 2,
     command_class: Grizzly.ZWave.CommandClasses.FirmwareUpdateMD,
     impl: Grizzly.ZWave.Commands.FirmwareMDReport,
     name: :firmware_md_report,
     params: [
       manufacturer_id: 297,
       firmware_id: 769,
       checksum: 16143,
       firmware_upgradable?: true,
       max_fragment_size: 40,
       other_firmware_ids: [32778]
     ]
   },
   command_ref: #Reference<0.1607448711.4278714369.34043>,
   node_id: 10,
   queued: false,
   queued_delay: 0,
   status: :complete,
   transmission_stats: [],
   type: :command
 }}
```

To check what firmware version is running on a node:

```elixir
iex> Grizzly.send_command(node_id, :firmware_md_get)
{:ok,
 %Grizzly.Report{
   command: %Grizzly.ZWave.Command{
     command_byte: 18,
     command_class: Grizzly.ZWave.CommandClasses.Version,
     impl: Grizzly.ZWave.Commands.VersionReport,
     name: :version_report,
     params: [
       library_type: :enhanced_slave,
       protocol_version: "4.24",
       firmware_version: "1.78",
       hardware_version: 255,
       other_firmware_versions: ["24.0"]
     ]
   },
   command_ref: #Reference<0.1607448711.4278714369.35718>,
   node_id: 10,
   queued: false,
   queued_delay: 0,
   status: :complete,
   transmission_stats: [],
   type: :command
 }}
```