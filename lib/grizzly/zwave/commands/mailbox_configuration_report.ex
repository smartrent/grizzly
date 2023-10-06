defmodule Grizzly.ZWave.Commands.MailboxConfigurationReport do
  @moduledoc """
  The Mailbox Configuration Report command is used to report the Mailbox configuration
  of a supporting device.

  Params:

  * `mode` - The current mailbox mode. See `t:Grizzly.ZWave.CommandClasses.Mailbox.mode/0`.
  * `supported_modes` - The mailbox modes supported by the device. See `t:Grizzly.ZWave.CommandClasses.Mailbox.supported_mode/0`.
  * `capacity` - The maximum number of messages that can be stored in the mailbox. A value of 0xFFFF means unlimited.
  * `destination_ipv6_address` - The IPv6 address of the destination mailbox service.
  * `destination_port` - The port number of the destination mailbox service.
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Mailbox

  @type param ::
          {:mode, Mailbox.mode()}
          | {:supported_modes, [Mailbox.supported_mode()]}
          | {:capacity, 0x0..0xFFFF}
          | {:destination_ipv6_address, :inet.ip6_address()}
          | {:destination_port, :inet.port_number()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :mailbox_configuration_report,
      command_byte: 0x03,
      command_class: Mailbox,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    mode = Command.param!(command, :mode)
    supported_modes = Command.param!(command, :supported_modes)
    capacity = Command.param!(command, :capacity)
    address = Command.param!(command, :destination_ipv6_address)
    port = Command.param!(command, :destination_port)

    <<0::3, Mailbox.encode_supported_modes(supported_modes)::2, Mailbox.encode_mode(mode)::3,
      capacity::16>> <> encode_ipv6_address(address) <> <<port::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(
        <<_reserved::3, supported_modes::2, mode::3, capacity::16, address::16-bytes, port::16>>
      ) do
    {:ok,
     [
       mode: Mailbox.decode_mode(mode),
       supported_modes: Mailbox.decode_supported_modes(supported_modes),
       capacity: capacity,
       destination_ipv6_address: decode_ipv6_address(address),
       destination_port: port
     ]}
  end
end
