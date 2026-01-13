defmodule Grizzly.ZWave.Commands.AntitheftUnlockReport do
  @moduledoc """
  This command is used to advertise the current locked/unlocked state of the
  node with some additional information.

  Params:

    * `:state` - This field MUST indicate the current :locked/:unlocked state of
      the device (required)
    * `:restricted` - This boolean field indicates whether the node currently
      runs in restricted mode (required)
    * `:manufacturer_id` - This field describes the Z-Wave Manufacturer ID of
      the company’s product that has locked the node (required)
    * `:antitheft_hint` - This field is used as a 1 to 10 byte identifier or key
      value to help retrieving the Magic Code (required)
    * `:locking_entity_id` - This field specifies a unique Z-Wave Alliance
      identifier for the entity that has locked the node (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.AntitheftUnlock

  @type param ::
          {:state, AntitheftUnlock.state()}
          | {:restricted, boolean}
          | {:manufacturer_id, non_neg_integer}
          | {:antitheft_hint, String.t()}
          | {:locking_entity_id, non_neg_integer}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    state_bit = Command.param!(command, :state) |> AntitheftUnlock.state_to_bit()
    restricted? = Command.param!(command, :restricted)
    restricted_bit = if restricted?, do: 1, else: 0
    hint = Command.param!(command, :antitheft_hint) |> AntitheftUnlock.validate_hint()
    manufacturer_id = Command.param!(command, :manufacturer_id)
    locking_entity_id = Command.param!(command, :locking_entity_id)

    <<0x00::2, byte_size(hint)::size(4), restricted_bit::1, state_bit::1>> <>
      hint <>
      <<manufacturer_id::16, locking_entity_id::16>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(
        _spec,
        <<_reserved::2, hint_length::4, restricted_bit::1, state_bit::1,
          hint::binary-size(hint_length), manufacturer_id::16, locking_entity_id::16>>
      ) do
    state = AntitheftUnlock.state_from_bit(state_bit)
    restricted? = restricted_bit == 1

    {:ok,
     [
       state: state,
       restricted: restricted?,
       antitheft_hint: hint,
       manufacturer_id: manufacturer_id,
       locking_entity_id: locking_entity_id
     ]}
  end
end
