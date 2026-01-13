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

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.DSK

  @type param ::
          {:seq_number, Grizzly.seq_number()}
          | {:input_dsk_length, 0..16}
          | {:dsk, DSK.t()}

  @impl Grizzly.ZWave.Command
  def validate_params(_spec, params) do
    :ok = validate_seq_number(params)
    :ok = validate_dsk(params)
    params = validate_and_ensure_input_dsk_length(params)
    {:ok, params}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    seq_number = Command.param!(command, :seq_number)
    input_dsk_length = Command.param!(command, :input_dsk_length)

    dsk = encode_dsk(Command.param!(command, :dsk))

    <<seq_number, input_dsk_length>> <> dsk
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<seq_number, _::4, input_dsk_length::4, dsk_bin::binary>>) do
    {:ok, [seq_number: seq_number, input_dsk_length: input_dsk_length, dsk: DSK.new(dsk_bin)]}
  end

  defp encode_dsk(%DSK{raw: raw}), do: raw
  defp encode_dsk(dsk_bin) when is_binary(dsk_bin), do: dsk_bin

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
