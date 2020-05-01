defmodule Grizzly.ZWave.Commands.VersionReport do
  @moduledoc """
  This module implements command VERSION_REPORT of command class COMMAND_CLASS_VERSION

  Params:

    * `:library_type` - The type of Z-Wave device library is running

    * `:protocol_version` - The "version.sub" implementd Z-Wave protocol

    * `:firmware_version` - The "version.sub" of the firmware

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Version

  @type library_type ::
          :static_controller
          | :controller
          | :enhanced_slave
          | :slave
          | :installer
          | :routing_slave
          | :bridge_controller
          | :device_under_test
          | :av_remote
          | :av_device
  @type protocol_version :: String.t()
  @type firmware_version :: String.t()
  @type param ::
          {:library_type, library_type}
          | {:protocol_version, protocol_version}
          | {:firmware_version, firmware_version}

  @impl true
  def new(params) do
    command = %Command{
      name: :version_report,
      command_byte: 0x12,
      command_class: Version,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def decode_params(
        <<library_type, protocol_version, protocol_sub_version, firmware_version,
          firmware_sub_version>>
      ) do
    with {:ok, library_type} <- decode_library_type(library_type) do
      {:ok,
       [
         library_type: library_type,
         protocol_version: "#{protocol_version}.#{protocol_sub_version}",
         firmware_version: "#{firmware_version}.#{firmware_sub_version}"
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

  @impl true
  def encode_params(command) do
    library_type = Command.param!(command, :library_type)
    protocol_version = Command.param!(command, :protocol_version)
    firmware_version = Command.param!(command, :firmware_version)
    library_type_byte = encode_library_type(library_type)
    {protocol_v, protocol_s} = split_version(protocol_version)
    {firmware_v, firmware_s} = split_version(firmware_version)
    <<library_type_byte, protocol_v, protocol_s, firmware_v, firmware_s>>
  end

  defp decode_library_type(0x01), do: {:ok, :static_controller}
  defp decode_library_type(0x02), do: {:ok, :controller}
  defp decode_library_type(0x03), do: {:ok, :enhanced_slave}
  defp decode_library_type(0x04), do: {:ok, :slave}
  defp decode_library_type(0x05), do: {:ok, :installer}
  defp decode_library_type(0x06), do: {:ok, :routing_slave}
  defp decode_library_type(0x07), do: {:ok, :bridge_controller}
  defp decode_library_type(0x08), do: {:ok, :device_under_test}
  defp decode_library_type(0x0A), do: {:ok, :av_remote}
  defp decode_library_type(0x0B), do: {:ok, :av_device}

  defp decode_library_type(byte),
    do:
      {:error,
       %DecodeError{
         value: byte,
         param: :library_type,
         command: :version_report
       }}

  defp encode_library_type(:static_controller), do: 0x01
  defp encode_library_type(:controller), do: 0x02
  defp encode_library_type(:enhanced_slave), do: 0x03
  defp encode_library_type(:slave), do: 0x04
  defp encode_library_type(:installer), do: 0x05
  defp encode_library_type(:routing_slave), do: 0x06
  defp encode_library_type(:bridge_controller), do: 0x07
  defp encode_library_type(:device_under_test), do: 0x08
  defp encode_library_type(:av_remote), do: 0x0A
  defp encode_library_type(:av_device), do: 0x0B

  defp split_version(version_with_sub) do
    [v, s] = String.split(version_with_sub, ".")
    {v_byte, ""} = Integer.parse(v)
    {s_byte, ""} = Integer.parse(s)
    {v_byte, s_byte}
  end
end
