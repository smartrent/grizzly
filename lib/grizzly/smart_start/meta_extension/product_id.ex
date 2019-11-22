defmodule Grizzly.SmartStart.MetaExtension.ProductId do
  @moduledoc """
  This Information Type is used to advertise the product identifying data of a supporting node.
  """
  @behaviour Grizzly.SmartStart.MetaExtension

  @type u16 :: 0x0000..0xFFFF

  @type param :: :manufacturer_id | :product_type | :product_id | :application_version

  @type t :: %__MODULE__{
          manufacturer_id: u16(),
          product_id: u16(),
          product_type: u16(),
          application_version: {byte(), byte()}
        }

  defstruct manufacturer_id: nil, product_type: nil, product_id: nil, application_version: nil

  defguardp is_u16(value) when value in 0x0000..0xFFFF

  @doc """
  Make a new `ProductId.t()`

  If a param is invalid this function will return
  `{:error, :invalid_params, param(), param_value}`
  """
  @spec new(
          manufacturer_id :: u16(),
          product_id :: u16(),
          product_type :: u16(),
          application_version :: {byte(), byte()}
        ) :: {:ok, t()} | {:error, :invalidate_param, param(), any()}
  def new(manufacturer_id, product_id, product_type, application_version) do
    with :ok <- validate_param(:manufacturer_id, manufacturer_id),
         :ok <- validate_param(:product_id, product_id),
         :ok <- validate_param(:product_type, product_type),
         :ok <- validate_param(:application_version, application_version) do
      {:ok,
       %__MODULE__{
         manufacturer_id: manufacturer_id,
         product_id: product_id,
         product_type: product_type,
         application_version: application_version
       }}
    end
  end

  @doc """
  Make a `ProductId.t()` from a binary string

  According to the specification for this extension the critical bit must not
  be set. If it is then the binary is not consider valid and should be
  ignored.
  """
  @impl Grizzly.SmartStart.MetaExtension
  @spec from_binary(binary()) :: {:ok, t()} | {:error, :critical_bit_set | :invalid_binary}
  def from_binary(
        <<1::size(7), 0::size(1), 0x08, manufacturer_id::size(16), product_type::size(16),
          product_id::size(16), application_version, application_sub_version>>
      ) do
    {:ok,
     %__MODULE__{
       manufacturer_id: manufacturer_id,
       product_id: product_id,
       product_type: product_type,
       application_version: {application_version, application_sub_version}
     }}
  end

  def from_binary(<<1::size(7), 1::size(1), _rest::binary>>) do
    {:error, :critical_bit_set}
  end

  def from_binary(_), do: {:error, :invalid_binary}

  @doc """
  Build a binary from a `ProductId.t()`

  The arguments for the `params()` other than application version should be
  unsigned 16 bit integers.
  """
  @impl Grizzly.SmartStart.MetaExtension
  @spec to_binary(t()) :: {:ok, binary()}
  def to_binary(%__MODULE__{
        manufacturer_id: manufacturer_id,
        product_type: product_type,
        product_id: product_id,
        application_version: application_version
      }) do
    {:ok,
     <<0x02, 0x08, manufacturer_id::size(16), product_type::size(16), product_id::size(16),
       elem(application_version, 0), elem(application_version, 1)>>}
  end

  defp validate_param(:manufacturer_id, mid) when is_u16(mid), do: :ok
  defp validate_param(:product_type, pt) when is_u16(pt), do: :ok
  defp validate_param(:product_id, pid) when is_u16(pid), do: :ok

  defp validate_param(:application_version, {v1, v2}) when v1 in 0x00..0xFF and v2 in 0x00..0xFF,
    do: :ok

  defp validate_param(param, value), do: {:error, :invalid_param_argument, param, value}
end
