defmodule Grizzly.CommandClass.NodeProvisioning.MetaExtension.MaxInclusionRequestInterval do
  @moduledoc """
  This is used to advertise if a power constrained Smart Start node will issue
  inclusion request at a higher interval value than the default 512 seconds.
  """

  @typedoc """
  The interval (in seconds) must be in the range of 640..12672 inclusive, and
  has to be in steps of 128 seconds.

  So after 640 the next valid interval is `640 + 128` which is `768` seconds.

  See `SDS13944 Node Provisioning Information Type Registry.pdf` section
  `3.1.2.3` for more information.
  """
  @type interval :: 640..12672

  @type t :: %__MODULE__{
          interval: interval()
        }

  defstruct interval: nil

  @doc """
  Make a `MaxInclusionRequestInterval.t()` from a binary string

  If the interval provided in the binary is invalid this function will return
  `{:error, :interval_too_big | :interval_too_small}`. See the typedoc for
  more information regarding the interval specification.

  If the critical bit is set this is considered invalid to the specification and
  the function will return `{:error, :critical_bit_set}`.
  """
  @spec from_binary(binary()) ::
          {:ok, t()} | {:error, :interval_too_big | :interval_too_small | :critical_bit_set}
  def from_binary(<<0x02::size(7), 0::size(1), 0x01, interval>>) do
    case interval_from_byte(interval) do
      {:ok, interval_seconds} ->
        {:ok, %__MODULE__{interval: interval_seconds}}

      error ->
        error
    end
  end

  def from_binary(<<0x02::size(7), 1::size(1), _rest::binary>>) do
    {:error, :critical_bit_set}
  end

  @doc """
  Make a binary string from a `MaxInclusionRequestInterval.t()`

  If the interval provided in the binary is invalid this function will return
  `{:error, :interval_too_big | :interval_too_small}`. See the typedoc for
  more information regarding the interval specification.
  """
  @spec to_binary(t()) ::
          {:ok, binary()}
          | {:error, :interval_too_small | :interval_too_big | :interval_step_invalid}
  def to_binary(%__MODULE__{interval: interval}) do
    case interval_to_byte(interval) do
      {:ok, byte} ->
        {:ok, <<0x04, 0x01, byte>>}

      error ->
        error
    end
  end

  defp interval_from_byte(interval) when interval < 5, do: {:error, :interval_too_small}
  defp interval_from_byte(interval) when interval > 99, do: {:error, :interval_too_big}

  defp interval_from_byte(byte) do
    steps = byte - 5
    {:ok, 640 + steps * 128}
  end

  defp interval_to_byte(interval) when interval < 640, do: {:error, :interval_too_small}
  defp interval_to_byte(interval) when interval > 12672, do: {:error, :interval_too_big}

  defp interval_to_byte(interval) do
    if Integer.mod(interval, 128) == 0 do
      {:ok, Integer.floor_div(interval - 640, 128)}
    else
      {:error, :interval_step_invalid}
    end
  end
end
