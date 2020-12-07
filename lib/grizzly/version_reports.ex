defmodule Grizzly.VersionReports do
  @moduledoc false

  # This module is for supporting extra commands version reports
  # as of right now this is focused on providing the version reports
  # as needed for Z-Wave certification and can be extended to support
  # other command classes and versions.

  alias Grizzly.ZWave.{Command, CommandClasses}
  alias Grizzly.ZWave.Commands.CommandClassReport

  @doc """
  Get the version report for the command class
  """
  @spec version_report_for(CommandClasses.command_class()) ::
          {:ok, Command.t()} | {:error, :command_not_supported}
  def version_report_for(:association = name) do
    CommandClassReport.new(command_class: name, version: 3)
  end

  def version_report_for(:association_group_info = name) do
    CommandClassReport.new(command_class: name, version: 1)
  end

  def version_report_for(:device_reset_locally = name) do
    CommandClassReport.new(command_class: name, version: 1)
  end

  def version_report_for(:multi_channel_association = name) do
    CommandClassReport.new(command_class: name, version: 3)
  end

  def version_report_for(:supervision = name) do
    CommandClassReport.new(command_class: name, version: 1)
  end

  def version_report_for(:multi_command = name) do
    CommandClassReport.new(command_class: name, version: 1)
  end

  def version_report_for(_) do
    {:error, :command_not_supported}
  end
end
