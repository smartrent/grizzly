defmodule Grizzly.ZWave.Commands.NodeAddDSKReport do
  @moduledoc """
  The Z-Wave Command `NODE_ADD_DSK_REPORT`

  This report is used by the including controller to ask for the DSK
  for the device that is being included.

  ## Params

    - `:seq_number` - sequence number for the command (required)
    - `:input_dsk_length` - the required number of bytes must be in the `:dsk`
       field to be authenticated (optional default: `0`)
    - `:dsk` - the DSK for the device see `Grizzly.ZWave.DSK` for more
       information (required)

  The `:input_dsk_length` field can be set to 0 if not provided. That means that
  device does not require any user input to the DSK set command to authenticate
  the device. This case is normal when `:s2_unauthenticated` or client side
  authentication has been given.
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{DSK, Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion

  @type param ::
          {:seq_number, Grizzly.seq_number()}
          | {:input_dsk_length, 0..16}
          | {:dsk, DSK.dsk_string()}

  @impl true
  @spec new([param]) :: {:ok, Command.t()}
  def new(params) do
    :ok = validate_seq_number(params)
    :ok = validate_dsk(params)
    params = validate_and_ensure_input_dsk_length(params)

    command = %Command{
      name: :node_add_dsk_report,
      command_byte: 0x13,
      command_class: NetworkManagementInclusion,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    input_dsk_length = Command.param!(command, :input_dsk_length)
    dsk = Command.param!(command, :dsk)
    {:ok, dsk_bin} = DSK.string_to_binary(dsk)

    <<seq_number, input_dsk_length>> <> dsk_bin
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number, _::size(4), input_dsk_length::size(4), dsk::binary>>) do
    case DSK.binary_to_string(dsk) do
      {:ok, dsk} ->
        {:ok, [seq_number: seq_number, input_dsk_length: input_dsk_length, dsk: dsk]}

      {:error, _} ->
        {:error, %DecodeError{param: :dsk, value: dsk, command: :node_add_dsk_report}}
    end
  end

  defp validate_seq_number(params) do
    case Keyword.get(params, :seq_number) do
      nil ->
        raise ArgumentError, """
        When building the Z-Wave command #{inspect(__MODULE__)} the param :seq_number is
        required.

        Please ensure you passing a :seq_number option to the command
        """

      seq_number when seq_number >= 0 and seq_number <= 255 ->
        :ok

      seq_number ->
        raise ArgumentError, """
        When build the Z-Wave command #{inspect(__MODULE__)} the param :seq_number should be
        be an integer between 0 and 255 (0xFF) inclusive.

        It looks like you passed: #{inspect(seq_number)}
        """
    end
  end

  defp validate_dsk(params) do
    case Keyword.get(params, :dsk) do
      nil ->
        raise ArgumentError, """
        When building the Z-Wave command #{inspect(__MODULE__)} the param :dsk is
        required.

        Please ensure you passing a :dsk option to the command
        """

      _dsk ->
        :ok
    end
  end

  def validate_and_ensure_input_dsk_length(params) do
    case Keyword.get(params, :input_dsk_length) do
      nil ->
        Keyword.put(params, :input_dsk_length, 0)

      length when length >= 0 and length <= 16 ->
        params

      length ->
        raise ArgumentError, """
        When build the Z-Wave command #{inspect(__MODULE__)} the param :input_dsk_length should be
        be an integer between 0 and 16 inclusive.

        It looks like you passed: #{inspect(length)}
        """
    end
  end
end
