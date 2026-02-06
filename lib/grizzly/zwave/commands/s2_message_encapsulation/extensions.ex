defmodule Grizzly.ZWave.Commands.S2MessageEncapsulation.Extensions do
  @moduledoc """
  Functions for working with S2 Message Encapsulation extensions.
  """

  import Grizzly.ZWave.Encoding

  @type extension_type :: :span | :mpan | :mgrp | :mos

  @type t :: [extension()]

  @type mpan :: %{group_id: 0..255, inner_mpan_state: <<_::128>>}

  @type extension ::
          {:span, senders_entropy_input :: binary()}
          | {:mpan, mpan()}
          | {:mgrp, group_id :: byte()}
          | {:mos, true}

  @type raw_extension :: %{
          critical?: boolean(),
          type: extension_type() | :unsupported,
          data: binary()
        }

  @spec from_binary(binary()) ::
          {:ok, {[extension()], remainder :: binary()}}
          | {:error, :unsupported_critical_extension}
  def from_binary(binary) do
    {extensions, remainder} = split_extensions(binary)

    if Enum.any?(extensions, &(&1.type == :unsupported && &1.critical?)) do
      {:error, :unsupported_critical_extension}
    else
      extensions = Enum.map(extensions, &parse_extension/1)
      {:ok, {extensions, remainder}}
    end
  end

  # Splits extensions into a list of binaries but doesn't decode them yet.
  @spec split_extensions(binary(), [raw_extension()]) :: {[raw_extension()], binary()}
  defp split_extensions(
         <<length::8, more_to_follow?::1, critical?::1, type::6, data::binary-size(length),
           rest::binary>>,
         acc \\ []
       ) do
    ext = %{critical?: bit_to_bool(critical?), type: decode_type(type), data: data}

    if bit_to_bool(more_to_follow?) do
      split_extensions(rest, [ext | acc])
    else
      {[ext | acc], rest}
    end
  end

  # defp encode_type(:span), do: 0x01
  # defp encode_type(:mpan), do: 0x02
  # defp encode_type(:mgrp), do: 0x03
  # defp encode_type(:mos), do: 0x04

  defp decode_type(0x01), do: :span
  defp decode_type(0x02), do: :mpan
  defp decode_type(0x03), do: :mgrp
  defp decode_type(0x04), do: :mos
  defp decode_type(_), do: :unsupported

  defp parse_extension(%{type: :span, data: <<senders_entropy_input::binary-size(16)>>}) do
    {:span, senders_entropy_input}
  end

  defp parse_extension(%{type: :mpan, data: <<group_id::8, inner_mpan_state::binary-size(16)>>}) do
    {:mpan, %{group_id: group_id, inner_mpan_state: inner_mpan_state}}
  end

  defp parse_extension(%{type: :mgrp, data: <<group_id::8>>}) do
    {:mgrp, group_id}
  end

  defp parse_extension(%{type: :mos, data: <<>>}) do
    {:mos, true}
  end
end
