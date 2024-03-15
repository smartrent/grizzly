defmodule Grizzly.ZWave.Commands.S2MessageEncapsulation do
  @moduledoc """
  Encapsulates a message for transmission using S2.

  ## Params

  * `:seq_number` - must carry an increment of the value carried in the previous
    outgoing message.
  * `:extensions` - a list of extensions to include with the command. Valid extensions
    are SPAN, MPAN, MGRP, and MOS.
  * `:encrypted_payload` - explain what `:encrypted_payload` param is for

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding
  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Security2

  @type param :: {:seq_number, byte()} | {:extensions, any()} | {:encrypted_payload, binary()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :s2_message_encapsulation,
      command_byte: 0x03,
      command_class: Security2,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    seq_number = Command.param!(command, :seq_number)
    all_extensions = Command.param(command, :extensions, [])
    encrypted_payload = Command.param!(command, :encrypted_payload)

    {encrypted_extensions, extensions} =
      Enum.split_with(all_extensions, &(elem(&1, 0) == :mpan))

    encrypted_extensions? = encrypted_extensions != []
    extensions? = extensions != []

    <<seq_number::8, 0::6, bool_to_bit(encrypted_extensions?)::1, bool_to_bit(extensions?)::1,
      encode_extensions(all_extensions)::binary, encrypted_payload::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number::8, _reserved::6, _encrypted_ext?::1, _ext?::1, rest::binary>>) do
    {extensions, encrypted_payload} = decode_extensions(rest)

    {:ok,
     [
       seq_number: seq_number,
       extensions: extensions,
       encrypted_payload: encrypted_payload
     ]}
  end

  # TODO: Implement this
  defp encode_extensions(_extensions) do
    <<>>
  end

  # TODO: Implement this
  defp decode_extensions(binary) do
    {[], binary}
  end
end
