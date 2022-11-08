defmodule Grizzly.ZWave.Commands.VersionZWaveSoftwareReport do
  @moduledoc """
  This module implements command VERSION_ZWAVE_SOFTWARE_REPORT of command class
  COMMAND_CLASS_VERSION

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Version, as: CCVersion

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :version_zwave_software_report,
      command_byte: 0x18,
      command_class: CCVersion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    sdk_version = Command.param(command, :sdk_version)
    app_framework_api_version = Command.param(command, :application_framework_api_version)
    app_framework_build_number = Command.param(command, :application_framework_build_number)
    host_interface_version = Command.param(command, :host_interface_version)
    host_interface_build_number = Command.param(command, :host_interface_build_number)
    zwave_protocol_version = Command.param(command, :zwave_protocol_version)
    zwave_protocol_build_number = Command.param(command, :zwave_protocol_build_number)
    application_version = Command.param(command, :application_version)
    application_build_number = Command.param(command, :application_build_number)

    encode_version(sdk_version) <>
      encode_version(app_framework_api_version, app_framework_build_number) <>
      encode_version(host_interface_version, host_interface_build_number) <>
      encode_version(zwave_protocol_version, zwave_protocol_build_number) <>
      encode_version(application_version, application_build_number)
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        <<sdk_version::24, app_framework_api_version::24, application_framework_build_number::16,
          host_interface_version::24, host_interface_build_number::16, zwave_protocol_version::24,
          zwave_protocol_build_number::16, application_version::24, application_build_number::16>>
      ) do
    {:ok,
     [
       sdk_version: decode_version(<<sdk_version::24>>),
       application_framework_api_version: decode_version(<<app_framework_api_version::24>>),
       application_framework_build_number: application_framework_build_number,
       host_interface_version: decode_version(<<host_interface_version::24>>),
       host_interface_build_number: host_interface_build_number,
       zwave_protocol_version: decode_version(<<zwave_protocol_version::24>>),
       zwave_protocol_build_number: zwave_protocol_build_number,
       application_version: decode_version(<<application_version::24>>),
       application_build_number: application_build_number
     ]}
  end

  defp encode_version(nil), do: <<0, 0, 0>>

  defp encode_version(version) do
    case Version.parse(version) do
      {:ok, %Version{major: major, minor: minor, patch: patch}} ->
        <<major::integer-size(8), minor::integer-size(8), patch::integer-size(8)>>

      :error ->
        <<0, 0, 0>>
    end
  end

  defp encode_version(version, build_number) do
    encode_version(version) <> <<build_number::integer-size(16)>>
  end

  defp decode_version(<<major::8, minor::8, patch::8>>), do: "#{major}.#{minor}.#{patch}"
end
