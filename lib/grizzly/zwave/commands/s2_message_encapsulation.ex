defmodule Grizzly.ZWave.Commands.S2MessageEncapsulation do
  @moduledoc """
  Encapsulates a message for transmission using S2.

  ## Params

  * `:seq_number` - must carry an increment of the value carried in the previous
    outgoing message.
  * `:extensions` - a list of extensions (SPAN, MGRP, MOS) to include with the command.
  * `:encrypted_extensions?` - when set, indicates that the command includes encrypted
    extensions (MPAN). Unlike `extensions?`, this param is required when encoding as
    it is impossible to determine if the encrypted payload contains extensions at that
    point.
  * `:encrypted_payload` - includes the encrypted extensions (if any), encrypted command
    payload, and auth tag


  ## Notes

  * Although this module's functions support encoding/decoding the MPAN extension,
    MPAN is an encrypted extension and must be included in the encrypted payload.
    As such, it will be ignored if provided in the `:extensions` param.
  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding
  alias Grizzly.ZWave.{Command, DecodeError}
  alias Grizzly.ZWave.CommandClasses.Security2

  @type extension_type :: :span | :mpan | :mgrp | :mos

  @type extension ::
          {:span, <<_::128>>}
          | {:mgrp, group_id :: byte()}
          | {:mos, boolean()}

  @type param ::
          {:seq_number, byte()}
          | {:extensions, list()}
          | {:encrypted_extensions?, boolean()}
          | {:encrypted_payload, binary()}

  @impl Grizzly.ZWave.Command
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    # MPAN is an encrypted extension, so reject it if it was included
    params = Keyword.replace(params, :extensions, reject_mpan(params[:extensions] || []))

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
  def encode_params(cmd) do
    seq_number = Command.param!(cmd, :seq_number)
    extensions = Command.param(cmd, :extensions, [])
    encrypted_extensions? = Command.param(cmd, :encrypted_extensions?, false)
    encrypted_payload = Command.param!(cmd, :encrypted_payload)

    ext = encode_extensions(extensions)
    extensions? = ext != <<>>

    <<seq_number::8, 0::6, bool_to_bit(encrypted_extensions?)::1, bool_to_bit(extensions?)::1,
      encode_extensions(extensions)::binary, encrypted_payload::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<seq_number::8, _reserved::6, encrypted_ext?::1, ext?::1, rest::binary>>) do
    {extensions, encrypted_payload} =
      if(ext? == 1,
        do: decode_extensions(rest),
        else: {[], rest}
      )

    {:ok,
     [
       seq_number: seq_number,
       extensions: extensions,
       encrypted_extensions?: bit_to_bool(encrypted_ext?),
       encrypted_payload: encrypted_payload
     ]}
  end

  def encode_extensions(extensions) do
    extensions =
      extensions
      |> reject_mpan()
      |> Enum.reject(fn {t, v} -> t == :mos and v == false end)

    encoded_extensions =
      for {type, value} <- extensions, into: [] do
        data = encode_extension_data(type, value)
        # we'll clear the more_to_follow bit on the last extension later
        length = byte_size(data) + 2
        critical? = if(type == :mos, do: 0, else: 1)
        type = encode_extension_type(type)
        <<length, 1::1, critical?::1, type::6, data::binary>>
      end

    encoded_extensions
    |> List.update_at(-1, fn <<length, _more_to_follow?::1, critical?::1, type::6, data::binary>> ->
      <<length, 0::1, critical?::1, type::6, data::binary>>
    end)
    |> Enum.join()
  end

  def decode_extensions(
        <<ext_length, more_to_follow?::1, _critical?::1, type::6,
          extension_data::binary-size(ext_length - 2), rest::binary>>,
        extensions \\ []
      ) do
    type = decode_extension_type(type)
    extensions = [{type, decode_extension_data(type, extension_data)} | extensions]

    if more_to_follow? == 1 do
      decode_extensions(rest, extensions)
    else
      {extensions, rest}
    end
  end

  defp encode_extension_data(:span, span), do: span
  defp encode_extension_data(:mos, true), do: <<>>
  defp encode_extension_data(:mgrp, group_id), do: <<group_id>>

  defp encode_extension_data(:mpan, value) do
    group_id = Keyword.fetch!(value, :group_id)
    mpan_state = Keyword.fetch!(value, :mpan_state)
    <<group_id, mpan_state>>
  end

  defp decode_extension_data(:span, span), do: span
  defp decode_extension_data(:mgrp, <<group_id>>), do: group_id
  defp decode_extension_data(:mos, <<>>), do: true

  defp decode_extension_data(:mpan, <<group_id, mpan_state::16-bytes>>),
    do: [group_id: group_id, mpan_state: mpan_state]

  defp encode_extension_type(:span), do: 1
  defp encode_extension_type(:mpan), do: 2
  defp encode_extension_type(:mgrp), do: 3
  defp encode_extension_type(:mos), do: 4

  defp decode_extension_type(1), do: :span
  defp decode_extension_type(2), do: :mpan
  defp decode_extension_type(3), do: :mgrp
  defp decode_extension_type(4), do: :mos

  @spec reject_mpan([extension()]) :: [extension()]
  defp reject_mpan(exts), do: Enum.reject(exts, fn {type, _} -> type == :mpan end)
end
