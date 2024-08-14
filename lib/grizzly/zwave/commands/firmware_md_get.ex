defmodule Grizzly.ZWave.Commands.FirmwareMDGet do
  @moduledoc """
  This module implements command FIRMWARE_MD_GET of command class
  COMMAND_CLASS_FIRMWARE_UPDATE_MD

  The command requests a FIRMWARE_MD_REPORT

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.FirmwareUpdateMD

  @impl Grizzly.ZWave.Command
  def new(_opts \\ []) do
    command = %Command{
      name: :firmware_md_get,
      command_byte: 0x01,
      command_class: FirmwareUpdateMD,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
