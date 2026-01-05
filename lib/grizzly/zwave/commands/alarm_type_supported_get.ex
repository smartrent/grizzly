defmodule Grizzly.ZWave.Commands.AlarmTypeSupportedGet do
  @moduledoc """
  This command is used to request supported Alarm/Notification Types.

  Params: -none-
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Alarm

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :alarm_type_supported_get,
      command_byte: 0x07,
      command_class: Alarm,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_command) do
    <<>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<>>) do
    {:ok, []}
  end
end
