defmodule Grizzly.SmartStart.MetaExtension.SmartStartInclusionSetting do
  @moduledoc """
  This extension is used to advertise the SmartStart inclusion setting of the
  provisioning list entry
  """

  @typedoc """
  The setting for SmartStart inclusion. This tells the controller if it must
  listen and/or include a node in the network when receiving SmartStart
  inclusion requests.

  - `:pending` - the node will be added to the network when it issues SmartStart
    inclusion requests.
  - `:passive` - this node is unlikely to issues a SmartStart inclusion request
    and SmartStart inclusion requests will be ignored from this node by the
    Z/IP Gateway. All nodes in the list with this setting must be updated to
    `:pending` when Provisioning List Iteration Get command is issued.
  - `:ignored` - All SmartStart inclusion request are ignored from this node
    until updated via Z/IP Client (Grizzly) or a controlling node.
  """
  @behaviour Grizzly.SmartStart.MetaExtension
  @type setting :: :pending | :passive | :ignored

  @type t :: %__MODULE__{
          setting: setting()
        }

  @enforce_keys [:setting]
  defstruct setting: nil

  @spec new(setting()) :: {:ok, t()} | {:error, :invalid_setting}
  def new(setting) do
    case validate_setting(setting) do
      :ok ->
        {:ok, %__MODULE__{setting: setting}}

      error ->
        error
    end
  end

  @doc """
  Make a `SmartStartInclusionSetting.t()` from a binary

  If the setting is invalid this function will return
  `{:error, :invalid_setting}`
  """
  @impl Grizzly.SmartStart.MetaExtension
  @spec to_binary(t()) :: {:ok, binary}
  def to_binary(%__MODULE__{setting: setting}) do
    setting_byte = setting_to_byte(setting)
    {:ok, <<0x34::size(7), 0x01::size(1), 0x01, setting_byte>>}
  end

  @doc """
  Make a binary from a `SmartStartInclusionSetting.t()`

  If the setting is invalid this function will return `{:error, :invalid_setting}`

  If the binary does not have the critical bit set then this function will
  return `{:error, :critical_bit_not_set}`
  """
  @impl Grizzly.SmartStart.MetaExtension
  @spec from_binary(binary()) ::
          {:ok, t()} | {:error, :invalid_setting | :critical_bit_not_set | :invalid_binary}
  def from_binary(<<0x34::size(7), 0x01::size(1), 0x01, setting_byte>>) do
    case setting_from_byte(setting_byte) do
      {:ok, setting} ->
        {:ok, %__MODULE__{setting: setting}}

      error ->
        error
    end
  end

  def from_binary(<<0x34, 0x00::size(1), _rest::binary>>) do
    {:error, :critical_bit_not_set}
  end

  def from_binary(_), do: {:error, :invalid_binary}

  defp validate_setting(setting) when setting in [:pending, :passive, :ignored], do: :ok
  defp validate_setting(_), do: {:error, :invalid_setting}

  defp setting_to_byte(:pending), do: 0x00
  defp setting_to_byte(:passive), do: 0x02
  defp setting_to_byte(:ignored), do: 0x03

  defp setting_from_byte(0x00), do: {:ok, :pending}
  defp setting_from_byte(0x02), do: {:ok, :passive}
  defp setting_from_byte(0x03), do: {:ok, :ignored}
  defp setting_from_byte(_), do: {:error, :invalid_setting}
end
