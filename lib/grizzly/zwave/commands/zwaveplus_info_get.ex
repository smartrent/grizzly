defmodule Grizzly.ZWave.Commands.ZwaveplusInfoGet do
  @moduledoc """
  Used to get additional information of a Z-Wave Plus device.

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.ZwaveplusInfo

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :zwaveplus_info_get,
      command_byte: 0x01,
      command_class: ZwaveplusInfo,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_binary) do
    {:ok, []}
  end
end
