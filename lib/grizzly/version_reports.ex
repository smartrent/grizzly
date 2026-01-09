defmodule Grizzly.VersionReports do
  @moduledoc false

  # This module is for supporting extra commands version reports
  # as of right now this is focused on providing the version reports
  # as needed for Z-Wave certification and can be extended to support
  # other command classes and versions.

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.Commands

  @extra_supported_commands [
    :association,
    :association_group_info,
    :device_reset_locally,
    :multi_channel_association,
    :multi_cmd,
    :supervision
  ]

  defguard is_extra_command(command) when command in @extra_supported_commands

  @doc """
  Get the version report for the command class
  """
  @spec version_report_for(CommandClasses.command_class()) ::
          {:ok, Command.t()} | {:error, :unknown_command}
  def version_report_for(:association = name) do
    Commands.create(:version_command_class_report, command_class: name, version: 3)
  end

  def version_report_for(:association_group_info = name) do
    Commands.create(:version_command_class_report, command_class: name, version: 3)
  end

  def version_report_for(:device_reset_locally = name) do
    Commands.create(:version_command_class_report, command_class: name, version: 1)
  end

  def version_report_for(:multi_channel_association = name) do
    Commands.create(:version_command_class_report, command_class: name, version: 4)
  end

  def version_report_for(:supervision = name) do
    Commands.create(:version_command_class_report, command_class: name, version: 1)
  end

  def version_report_for(:multi_cmd = name) do
    Commands.create(:version_command_class_report, command_class: name, version: 1)
  end

  def version_report_for(_) do
    {:error, :unknown_command}
  end
end
