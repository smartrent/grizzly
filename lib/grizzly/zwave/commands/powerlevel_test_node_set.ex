defmodule Grizzly.ZWave.Commands.PowerlevelTestNodeSet do
  @moduledoc """
  This command is used to instruct the destination node to transmit a number of test frames to the
  specified NodeID with the RF power level specified. After the test frame transmissions the RF power
  level is reset to normal and the result (number of acknowledged test frames) is saved for subsequent
  read-back. The result of the test may be requested with a Powerlevel Test Node Get Command.

  Params:

    * `:test_node_id` - The id of the node that should receive the test frames.

    * `:power_level` - The power level indicator value to use in the test frame transmission.

    * `:test_frame_count` - The number of test frames to transmit to the test node

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Powerlevel

  @type param ::
          {:test_node_id, Grizzly.node_id()}
          | {:power_level, Powerlevel.power_level()}
          | {:test_frame_count, non_neg_integer()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :powerlevel_test_node_set,
      command_byte: 0x04,
      command_class: Powerlevel,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    test_node_id = Command.param!(command, :test_node_id)
    power_level_byte = Command.param!(command, :power_level) |> Powerlevel.power_level_to_byte()
    test_frame_count = Command.param!(command, :test_frame_count)
    <<test_node_id, power_level_byte, test_frame_count::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<test_node_id, power_level_byte, test_frame_count::16>>) do
    with {:ok, power_level} <- Powerlevel.power_level_from_byte(power_level_byte) do
      {:ok,
       [test_node_id: test_node_id, power_level: power_level, test_frame_count: test_frame_count]}
    else
      {:error, %DecodeError{} = error} ->
        {:error, %DecodeError{error | command: :powerlevel_test_node_set}}
    end
  end
end
