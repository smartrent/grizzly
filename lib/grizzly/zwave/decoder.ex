defmodule Grizzly.ZWave.Decoder do
  @moduledoc false

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands

  @spec from_binary(binary) :: {:ok, Command.t()}
  # Switch Binary (0x25)
  def from_binary(<<0x25, 0x01, params::binary>>),
    do: decode(Commands.SwitchBinarySet, params)

  def from_binary(<<0x25, 0x02>>),
    do: decode(Commands.SwitchBinaryGet, [])

  def from_binary(<<0x25, 0x03, params::binary>>),
    do: decode(Commands.SwitchBinaryReport, params)

  # Network Management Inclusion (0x34)
  def from_binary(<<0x34, 0x01, params::binary>>), do: decode(Commands.NodeAdd, params)
  def from_binary(<<0x34, 0x02, params::binary>>), do: decode(Commands.NodeAddStatus, params)
  def from_binary(<<0x34, 0x03, params::binary>>), do: decode(Commands.NodeRemove, params)
  def from_binary(<<0x34, 0x04, params::binary>>), do: decode(Commands.NodeRemoveStatus, params)
  def from_binary(<<0x34, 0x11, params::binary>>), do: decode(Commands.NodeAddKeysReport, params)
  def from_binary(<<0x34, 0x12, params::binary>>), do: decode(Commands.NodeAddKeysSet, params)
  def from_binary(<<0x34, 0x13, params::binary>>), do: decode(Commands.NodeAddDSKReport, params)
  def from_binary(<<0x34, 0x14, params::binary>>), do: decode(Commands.NodeAddDSKSet, params)

  # Network Management Basic Node (0x4D)
  def from_binary(<<0x4D, 0x07, params::binary>>), do: decode(Commands.DefaultSetComplete, params)

  # Network Management Proxy (0x52)
  def from_binary(<<0x52, 0x01, params::binary>>), do: decode(Commands.NodeListGet, params)
  def from_binary(<<0x52, 0x02, params::binary>>), do: decode(Commands.NodeListReport, params)

  def from_binary(<<0x52, 0x04, params::binary>>),
    do: decode(Commands.NodeInfoCacheReport, params)

  # Association (0x85)
  def from_binary(<<0x85, 0x03, params::binary>>), do: decode(Commands.AssociationReport, params)

  defp decode(command_impl, params) do
    decoded_params = command_impl.decode_params(params)
    command_impl.new(decoded_params)
  end
end
