defmodule Grizzly.ZWave.CommandClasses do
  @moduledoc """
  Utilities for encoding and decoding command classes and command class lists.
  """

  require Logger

  import Grizzly.ZWave.GeneratedMappings, only: [command_class_mappings: 0]

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
    binary_list = :erlang.binary_to_list(binary)

    {_, command_classes} =
      Enum.reduce(
        binary_list,
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

          0xF1, {_, command_classes} ->
            {:secure_supported, command_classes}

          0x00, {_, command_classes} ->
            {:secure_supported, command_classes}

          0xEF, {:secure_supported, command_classes} ->
            {:secure_controlled, command_classes}

          command_class_byte, {security, command_classes}
          when command_class_byte not in [0xF1, 0xEF, 0x00] ->
            case from_byte(command_class_byte) do
              {:ok, command_class} ->
                {security,
                 Keyword.update(command_classes, security, [], &(&1 ++ [command_class]))}

              {:error, :unsupported_command_class} ->
                # Skip unsupported command classes
                {security, command_classes}
            end
        end
      )

    command_classes
  end

  def maybe_concat_command_classes(binary, _, <<>>), do: binary

  def maybe_concat_command_classes(binary, :non_secure_controlled, ccs_bin),
    do: binary <> <<0xEF, ccs_bin::binary>>

  def maybe_concat_command_classes(binary, :secure_supported, ccs_bin),
    do: binary <> <<0xF1, 0x00, ccs_bin::binary>>

  def maybe_concat_command_classes(binary, :secure_controlled, ccs_bin),
    do: binary <> <<0xEF, ccs_bin::binary>>
end
