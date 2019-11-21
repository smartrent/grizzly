defmodule Grizzly.CommandClass.NodeProvisioning.MetaExtension.BootstrappingMode do
  @moduledoc """
  This extension is used to advertise the bootstrapping mode to use when
  including the node advertised in the provisioning list
  """

  @typedoc """
  The modes are:

  - `:security_2` - the node must be manually set to learn mode and follow the
    S2 bootstrapping instructions
  - `:smart_start` - the node will use S2 bootstrapping automatically using the
    SmartStart functionality
  """
  @type mode :: :security_2 | :smart_start

  @type t :: %__MODULE__{
          mode: mode()
        }

  @enforce_keys [:mode]
  defstruct mode: nil

  @doc """
  Create a `BootstrappingMode.t()`
  """
  @spec new(mode()) :: {:ok, t()} | {:error, :invalid_mode}
  def new(mode) when mode in [:security_2, :smart_start] do
    {:ok, %__MODULE__{mode: mode}}
  end

  def new(_), do: {:error, :invalid_mode}

  @doc """
  Make a binary from a `BootstrappingMode.t()`
  """
  @spec to_binary(t()) :: {:ok, binary()}
  def to_binary(%__MODULE__{mode: mode}) do
    {:ok, <<0x36::size(7), 1::size(1), 0x01, mode_to_byte(mode)>>}
  end

  @doc """
  Make a `BootstrappingMode.t()` from a binary

  The binary string for this extension requires the critical bit to be set and
  if it is not this function will return `{:error, :critical_bit_not_set}`
  """
  @spec from_binary(binary()) :: {:ok, t()} | {:error, :critical_bit_not_set}
  def from_binary(<<0x36::size(7), 1::size(1), 0x01, mode_byte>>) do
    case mode_from_byte(mode_byte) do
      {:ok, mode} ->
        new(mode)

      error ->
        error
    end
  end

  def from_binary(<<0x36::size(7), 0::size(1), _rest::binary>>) do
    {:error, :critical_bit_not_set}
  end

  defp mode_to_byte(:security_2), do: 0x00
  defp mode_to_byte(:smart_start), do: 0x01

  defp mode_from_byte(0x00), do: {:ok, :security_2}
  defp mode_from_byte(0x01), do: {:ok, :smart_start}
  defp mode_from_byte(_mode), do: {:error, :invalid_mode}
end
