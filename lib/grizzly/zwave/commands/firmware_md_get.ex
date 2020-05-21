defmodule Grizzly.ZWave.Commands.FirmwareMDGet do
  @moduledoc """
  This module implements command FIRMWARE_MD_GET of command class COMMAND_CLASS_FIRMWARE_UPDATE_MD
  The command requests a FIRMWARE_MD_REPORT

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.FirmwareUpdateMD

  @impl true
  def new(_opts \\ []) do
    command = %Command{
      name: :firmware_md_get,
      command_byte: 0x01,
      command_class: FirmwareUpdateMD,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(_command) do
    <<>>
  end

  @impl true
  def decode_params(_binary) do
    {:ok, []}
  end
end
