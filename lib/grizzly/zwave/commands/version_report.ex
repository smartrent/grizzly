defmodule Grizzly.ZWave.Commands.VersionReport do
  @moduledoc """
  This module implements command VERSION_REPORT of command class COMMAND_CLASS_VERSION

  Params:

    * `:library_type` - The type of Z-Wave device library is running

    * `:protocol_version` - The "version.sub" of the implemented Z-Wave protocol

    * `:firmware_version` - The "version.sub" of the firmware

    * `:hardware_version` - the hardware version - v2

    * `:other_firmware_versions` -  The list of "version.sub" of the other firmware targets - v2

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
          | {:hardware_version, non_neg_integer}
          | {:other_firmware_versions, [firmware_version]}

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
  # Version 1
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

  # Version 2
  def decode_params(
        <<library_type, protocol_version, protocol_sub_version, firmware_version,
          firmware_sub_version, hardware_version, firmware_targets,
          other_firmware_version_data::size(firmware_targets)-binary-unit(16)>>
      ) do
    with {:ok, library_type} <- decode_library_type(library_type) do
      other_firmware_versions = for <<v::8, s::8 <- other_firmware_version_data>>, do: "#{v}.#{s}"

      {:ok,
       [
         library_type: library_type,
         protocol_version: "#{protocol_version}.#{protocol_sub_version}",
         firmware_version: "#{firmware_version}.#{firmware_sub_version}",
         hardware_version: hardware_version,
         other_firmware_versions: other_firmware_versions
       ]}
    else
      {:error, %DecodeError{}} = error ->
        error
    end
  end

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
    hardware_version = Command.param(command, :hardware_version)

    if hardware_version == nil do
      <<library_type_byte, protocol_v, protocol_s, firmware_v, firmware_s>>
    else
      other_firmware_versions = Command.param!(command, :other_firmware_versions)
      number_of_firmware_targets = Enum.count(other_firmware_versions)
      other_firmware_version_data = encode_other_firmware_versions(other_firmware_versions)

      <<library_type_byte, protocol_v, protocol_s, firmware_v, firmware_s, hardware_version,
        number_of_firmware_targets, other_firmware_version_data::binary()>>
    end
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

  defp encode_other_firmware_versions(other_firmware_versions) do
    for other_firmware_version <- other_firmware_versions, into: <<>> do
      {v, s} = split_version(other_firmware_version)
      <<v, s>>
    end
  end

  defp split_version(version_with_sub) do
    [v, s] = String.split(version_with_sub, ".")
    {v_byte, ""} = Integer.parse(v)
    {s_byte, ""} = Integer.parse(s)
    {v_byte, s_byte}
  end
end
