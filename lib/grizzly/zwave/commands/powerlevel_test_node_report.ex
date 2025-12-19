defmodule Grizzly.ZWave.Commands.PowerlevelTestNodeReport do
  @moduledoc """
  This command is used to report the latest result of a test frame transmission started by the Powerlevel
  Test Node Set Command.

  Params:

     * `:test_node_id` - The id of the node that received the test frames.

    * `:test_frame_count` - The number of test frames transmitted to the test node

    * `:status_of_operation` The result of the last test

  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Powerlevel
  alias Grizzly.ZWave.DecodeError

  @type param ::
          {:test_node_id, Grizzly.node_id()}
          | {:status_of_operation, Powerlevel.status_of_operation()}
          | {:test_frame_count, non_neg_integer()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :powerlevel_test_node_report,
      command_byte: 0x06,
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

    status_of_operation_byte =
      Command.param!(command, :status_of_operation) |> Powerlevel.status_of_operation_to_byte()

    test_frame_count = Command.param!(command, :test_frame_count)
    <<test_node_id, status_of_operation_byte, test_frame_count::16>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<test_node_id, status_of_operation_byte, test_frame_count::16>>) do
    with {:ok, status_of_operation} <-
           Powerlevel.status_of_operation_from_byte(status_of_operation_byte) do
      {:ok,
       [
         test_node_id: test_node_id,
         status_of_operation: status_of_operation,
         test_frame_count: test_frame_count
       ]}
    else
      {:error, %DecodeError{} = error} ->
        {:error, %DecodeError{error | command: :powerlevel_test_node_report}}
    end
  end
end
