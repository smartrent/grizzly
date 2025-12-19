defmodule Grizzly.ZWave.Commands.ZwaveplusInfoReport do
  @moduledoc """
  This command reports the version of the Z-Wave Plus framework used and
  provides additional information of the Z-Wave Plus device.

  Params:

    * `:zwaveplus_version` - the Z-Wave Plus framework version (required)

    * `:role_type` - the role the Z-Wave Plus device  (required)

    * `:node_type` - the type of node the Z-Wave Plus device  (required)

    * `:installer_icon_type` - the icon to use in Graphical User Interfaces for network management  (required)

    * `:user_icon_type` - the icon to use in Graphical User Interfaces for end users  (required)

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ZwaveplusInfo
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:zwaveplus_version, 1 | 2}
          | {:role_type, ZwaveplusInfo.role_type()}
          | {:node_type, ZwaveplusInfo.node_type()}
          | {:installer_icon_type, non_neg_integer}
          | {:user_icon_type, non_neg_integer}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :zwaveplus_info_report,
      command_byte: 0x02,
      command_class: ZwaveplusInfo,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    zwaveplus_version = Command.param!(command, :zwaveplus_version)
    role_type_byte = Command.param!(command, :role_type) |> ZwaveplusInfo.role_type_to_byte()
    node_type_byte = Command.param!(command, :node_type) |> ZwaveplusInfo.node_type_to_byte()
    installer_icon_type = Command.param!(command, :installer_icon_type)
    user_icon_type = Command.param!(command, :user_icon_type)

    <<zwaveplus_version, role_type_byte, node_type_byte, installer_icon_type::16,
      user_icon_type::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(
        <<zwaveplus_version, role_type_byte, node_type_byte, installer_icon_type::16,
          user_icon_type::16>>
      ) do
    with {:ok, role_type} <- ZwaveplusInfo.role_type_from_byte(role_type_byte),
         {:ok, node_type} <- ZwaveplusInfo.node_type_from_byte(node_type_byte) do
      {:ok,
       [
         zwaveplus_version: zwaveplus_version,
         role_type: role_type,
         node_type: node_type,
         installer_icon_type: installer_icon_type,
         user_icon_type: user_icon_type
       ]}
    else
      {:error, %DecodeError{} = decode_error} ->
        {:error, %DecodeError{decode_error | command: :zwaveplus_info_report}}
    end
  end
end
