defmodule Grizzly.ZWave.CommandClasses do
  @moduledoc """
  Utilities for encoding and decoding command classes and command class lists.
  """

  import Grizzly.ZWave.GeneratedMappings, only: [command_class_mappings: 0]

  require Logger

  @type command_class_list :: [
          non_secure_supported: list(atom()),
          non_secure_controlled: list(atom()),
          secure_supported: list(atom()),
          secure_controlled: list(atom())
        ]

  mappings = command_class_mappings()

  command_classes_union =
    mappings
    |> Enum.map(&elem(&1, 1))
    |> Enum.reverse()
    |> Enum.reduce(&{:|, [], [&1, &2]})

  @type command_class :: unquote(command_classes_union)

  @doc """
  Get the byte representation of the command class
  """
  @spec to_byte(command_class()) :: byte()
  for {byte, command_class} <- mappings do
    def to_byte(unquote(command_class)), do: unquote(byte)
  end

  @spec from_byte(byte()) :: {:ok, command_class()} | {:error, :unsupported_command_class}
  for {byte, command_class} <- mappings do
    def from_byte(unquote(byte)), do: {:ok, unquote(command_class)}
  end

  def from_byte(byte) do
    Logger.warning("[Grizzly] Unsupported command class from byte #{inspect(byte, base: :hex)}")

    {:error, :unsupported_command_class}
  end

  @doc """
  Merges command class lists in a way that's more resilient to some Z/IP Gateway
  bugs. The list provided in the second argument is merged into the first.

  In particular, there's a Z/IP Gateway bug where it can lose track of a node's
  supported command classes. If this happens while the node is failing, a Node
  Info Cached Report can come back with an empty command class list. If requesting
  the NIF works but the controller doesn't receive an S0/S2 Commands Supported Report
  (e.g. due to interference), the secure command class lists will be empty.
  """
  @spec merge(command_class_list(), command_class_list()) :: command_class_list()
  def merge(list1, list2) do
    Keyword.merge(list1, list2, fn _key, val1, val2 ->
      if val2 == [] do
        val1
      else
        val2
      end
    end)
  end

  @doc """
  Turn the list of command classes into the binary representation outlined in
  the Network-Protocol command class specification.

  TODO: add more details
  """
  @spec command_class_list_to_binary([command_class_list()]) :: binary()
  def command_class_list_to_binary(command_class_list) do
    non_secure_supported = Keyword.get(command_class_list, :non_secure_supported, [])
    non_secure_controlled = Keyword.get(command_class_list, :non_secure_controlled, [])
    secure_supported = Keyword.get(command_class_list, :secure_supported, [])
    secure_controlled = Keyword.get(command_class_list, :secure_controlled, [])
    non_secure_supported_bin = for cc <- non_secure_supported, into: <<>>, do: <<to_byte(cc)>>
    non_secure_controlled_bin = for cc <- non_secure_controlled, into: <<>>, do: <<to_byte(cc)>>
    secure_supported_bin = for cc <- secure_supported, into: <<>>, do: <<to_byte(cc)>>
    secure_controlled_bin = for cc <- secure_controlled, into: <<>>, do: <<to_byte(cc)>>

    bin =
      non_secure_supported_bin
      |> maybe_concat_command_classes(:non_secure_controlled, non_secure_controlled_bin)
      |> maybe_concat_command_classes(:secure_supported, secure_supported_bin)
      |> maybe_concat_command_classes(:secure_controlled, secure_controlled_bin)

    if bin == <<>> do
      <<0>>
    else
      bin
    end
  end

  @doc """
  Turn the binary representation that is outlined in the Network-Protocol specs
  """
  @spec command_class_list_from_binary(binary()) :: [command_class_list()]
  def command_class_list_from_binary(binary) do
    binary
    |> :erlang.binary_to_list()
    |> group_extended_command_classes()
    |> parse_and_categorize_command_classes()
  end

  defp group_extended_command_classes(command_class_id_list) do
    command_class_id_list
    |> Enum.reduce({nil, []}, fn
      # Extended command classes start with 0xF1..0xFF
      byte, {nil, acc} when byte in 0xF1..0xFF ->
        {byte, acc}

      # Second byte of an extended command class
      byte, {prev_byte, acc} when prev_byte in 0xF1..0xFF ->
        {nil, [prev_byte * 2 ** 8 + byte | acc]}

      # All other command classes
      byte, {nil, acc} ->
        {nil, [byte | acc]}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp parse_and_categorize_command_classes(command_class_id_list) do
    command_class_id_list
    |> Enum.reduce(
      {:non_secure_supported,
       [
         non_secure_supported: [],
         non_secure_controlled: [],
         secure_supported: [],
         secure_controlled: []
       ]},
      fn
        0xEF, {:non_secure_supported, command_classes} ->
          {:non_secure_controlled, command_classes}

        0xF100, {_, command_classes} ->
          {:secure_supported, command_classes}

        0xEF, {:secure_supported, command_classes} ->
          {:secure_controlled, command_classes}

        # Skip extended command classes
        command_class_id, acc when command_class_id > 0xFF ->
          acc

        command_class_id, {security, command_classes} ->
          case from_byte(command_class_id) do
            {:ok, command_class} ->
              {security, Keyword.update(command_classes, security, [], &(&1 ++ [command_class]))}

            {:error, :unsupported_command_class} ->
              # Skip unsupported command classes
              {security, command_classes}
          end
      end
    )
    |> elem(1)
  end

  defp maybe_concat_command_classes(binary, _, <<>>), do: binary

  defp maybe_concat_command_classes(binary, :non_secure_controlled, ccs_bin),
    do: binary <> <<0xEF, ccs_bin::binary>>

  defp maybe_concat_command_classes(binary, :secure_supported, ccs_bin),
    do: binary <> <<0xF1, 0x00, ccs_bin::binary>>

  defp maybe_concat_command_classes(binary, :secure_controlled, ccs_bin),
    do: binary <> <<0xEF, ccs_bin::binary>>
end
