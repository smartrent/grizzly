defmodule Grizzly.ZWave.Commands.S0MessageEncapsulation do
  @moduledoc """
  This command is used to request an external nonce from the receiving node.
  """
  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.S0

  @impl Grizzly.ZWave.Command
  def new(params \\ []) do
    command = %Command{
      name: :s0_message_encapsulation,
      command_byte: 0x81,
      command_class: S0,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    sender_nonce = Command.param!(command, :sender_nonce)
    # second_frame? = Command.param!(command, :second_frame?)
    # sequenced? = Command.param!(command, :sequenced?)
    # sequence_counter = Command.param!(command, :sequence_counter)
    encrypted_payload = Command.param!(command, :encrypted_payload)
    receiver_nonce_identifier = Command.param!(command, :receiver_nonce_identifier)
    mac = Command.param!(command, :mac)

    <<sender_nonce::binary, encrypted_payload::binary, receiver_nonce_identifier::8,
      mac::binary-size(8)>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<sender_nonce::binary-size(8), rest::binary>>) do
    encrypted_payload = binary_slice(rest, 0..-10//1)
    <<receiver_nonce_identifier::8, mac::binary>> = binary_slice(rest, -9..-1)

    {:ok,
     [
       sender_nonce: sender_nonce,
       #  sequence_byte: sequence_byte,
       #  second_frame?: bit_to_bool(second_frame?),
       #  sequenced?: bit_to_bool(sequenced?),
       #  sequence_counter: sequence_counter,
       encrypted_payload: encrypted_payload,
       receiver_nonce_identifier: receiver_nonce_identifier,
       mac: mac
     ]}
  end
end
