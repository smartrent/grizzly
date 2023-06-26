defmodule Grizzly.ZWave.Commands.MailboxConfigurationSet do
  @moduledoc """
  The Mailbox Configuration Set command is used to update the Mailbox configuration
  from a supporting device.

  Params:

  * `mode` - The mailbox mode to set. See `t:Grizzly.ZWave.CommandClasses.Mailbox.mode/0`
  * `destination_ipv6_address` - The IPv6 address of the destination mailbox service.
  * `destination_port` - The port number of the destination mailbox service.
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Utils
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Mailbox

  @type param ::
          {:mode, Mailbox.mode()}
          | {:destination_ipv6_address, :inet.ip6_address()}
          | {:destination_port, :inet.port_number()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :mailbox_configuration_set,
      command_byte: 0x02,
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
    address = Command.param!(command, :destination_ipv6_address)
    port = Command.param!(command, :destination_port)

    <<0::5, Mailbox.encode_mode(mode)::3>> <> encode_ipv6_address(address) <> <<port::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]}
  def decode_params(<<_reserved::5, mode::3, address::binary-16, port::16>>) do
    {:ok,
     [
       mode: Mailbox.decode_mode(mode),
       destination_ipv6_address: decode_ipv6_address(address),
       destination_port: port
     ]}
  end
end
