defmodule Grizzly.ZWave.Commands.AntitheftSet do
  @moduledoc """
  This command is used to lock or unlock a node.

  Params:

    * `:state` - This field MUST indicate the desired :locked or :unlocked state
      for the receiving node (required v2+)
    * `:magic_code` - This field contains the 1 to 10 byte Magic Code used to
      lock or unlock the node (required v2+)
    * `:manufacturer_id` - This field describes the Z-Wave Manufacturer ID of the
      company’s product that has locked the node (required v2+)
    * `:antitheft_hint` - This field is used as a 1 to 10 byte identifier or key
      value to help retriving the Magic Code (required v2+)
    * `:locking_entity_id` - This field MUST specify a unique Z-Wave Alliance
      identifier for the entity that has locked the node (required v3)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Antitheft

  @type param ::
          {:state, Antitheft.lock_state()}
          | {:magic_code, String.t()}
          | {:manufacturer_id, non_neg_integer}
          | {:antitheft_hint, String.t()}
          | {:locking_entity_id, non_neg_integer}

  @impl true
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :antitheft_set,
      command_byte: 0x01,
      command_class: Antitheft,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    state_bit = Command.param!(command, :state) |> Antitheft.state_to_bit()
    magic_code = Command.param!(command, :magic_code) |> Antitheft.validate_magic_code_or_hint()
    manufacturer_id = Command.param!(command, :manufacturer_id)

    antitheft_hint =
      Command.param!(command, :antitheft_hint) |> Antitheft.validate_magic_code_or_hint()

    locking_entity_id = Command.param(command, :locking_entity_id)

    if locking_entity_id == nil do
      <<state_bit::size(1), byte_size(magic_code)::size(7)>> <>
        magic_code <>
        <<manufacturer_id::size(16), byte_size(antitheft_hint)>> <>
        antitheft_hint
    else
      <<state_bit::size(1), byte_size(magic_code)::size(7)>> <>
        magic_code <>
        <<manufacturer_id::size(16), byte_size(antitheft_hint)>> <>
        antitheft_hint <>
        <<locking_entity_id::size(16)>>
    end
  end

  @impl true
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  # v3
  def decode_params(
        <<state_bit::size(1), magic_code_length::size(7),
          magic_code::binary-size(magic_code_length), manufacturer_id::size(16),
          antitheft_hint_length, antitheft_hint::binary-size(antitheft_hint_length),
          locking_entity_id::size(16)>>
      ) do
    state = Antitheft.state_from_bit(state_bit)

    {:ok,
     [
       state: state,
       magic_code: magic_code,
       manufacturer_id: manufacturer_id,
       antitheft_hint: antitheft_hint,
       locking_entity_id: locking_entity_id
     ]}
  end

  # v2
  def decode_params(
        <<state_bit::size(1), magic_code_length::size(7),
          magic_code::binary-size(magic_code_length), manufacturer_id::size(16),
          antitheft_hint_length, antitheft_hint::binary-size(antitheft_hint_length)>>
      ) do
    state = Antitheft.state_from_bit(state_bit)

    {:ok,
     [
       state: state,
       magic_code: magic_code,
       manufacturer_id: manufacturer_id,
       antitheft_hint: antitheft_hint
     ]}
  end
end
