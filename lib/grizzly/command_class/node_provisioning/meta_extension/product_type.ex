defmodule Grizzly.CommandClass.NodeProvisioning.MetaExtension.ProductType do
  @moduledoc """
  This Information Type is used to advertise the product type data of a
  supporting node
  """
  alias Grizzly.IconType
  alias Grizzly.CommandClass.Mappings

  @typedoc """
  The generic and specific device classes are what is advertised in the
  Node Information Frame (NIF)

  The installer icon for the specific device see `Grizzly.IconType` for
  more information
  """
  @type t :: %__MODULE__{
          generic_device_class: atom(),
          specific_device_class: atom(),
          installer_icon: IconType.icon_name()
        }

  defstruct generic_device_class: nil, specific_device_class: nil, installer_icon: nil

  defguardp is_byte(value) when value in 0x00..0xFF

  @doc """
  Make a `ProductType.t()` from a binary string

  According to the specification for this extension the critical bit must not
  be set. If it is then the binary is not consider valid and should be
  ignored.
  """
  @spec from_binary(binary()) :: {:ok, t()} | {:error, :critical_bit_set}
  def from_binary(
        <<0::size(7), 0::size(1), 0x04, gen_dev_class, spec_dev_class, installer_icon::size(16)>>
      ) do
    {:ok, installer_icon} = IconType.from_integer(installer_icon)
    generic_class = Mappings.byte_to_generic_class(gen_dev_class)
    spec_class = Mappings.byte_to_specific_class(gen_dev_class, spec_dev_class)

    {:ok,
     %__MODULE__{
       generic_device_class: generic_class,
       specific_device_class: spec_class,
       installer_icon: installer_icon
     }}
  end

  def from_binary(<<0::size(7), 1::size(1), _rest::binary>>) do
    {:error, :critical_bit_set}
  end

  @doc """
  Build a binary from a `ProductType.t()`

  If there is invalid device classes or installer icon type with will return
  `{:error, reason}` where reason is:

  * `:invalid_generic_device_class` - the generic device class could not be 
     encoded into its byte representation
  * `:invalid_specific_device_class` - the specific device class could nto be
     encoded into its byte representation
  * `:unknown_icon_type` - the installer icon type cannot be encoded into its 
     byte representation
  """
  @spec to_binary(t()) ::
          {:ok, binary()}
          | {:error,
             :invalid_generic_device_class | :invalid_specific_device_class | :unknown_icon_type}
  def to_binary(%__MODULE__{
        generic_device_class: gdc,
        specific_device_class: sdc,
        installer_icon: icon
      }) do
    with gen_byte when is_byte(gen_byte) <- Mappings.generic_class_to_byte(gdc),
         spec_byte when is_byte(spec_byte) <- Mappings.specific_class_to_byte(gdc, sdc),
         {:ok, icon_integer} <- IconType.to_integer(icon) do
      {:ok, <<0x00, 0x04, gen_byte, spec_byte, icon_integer::size(16)>>}
    else
      {:unk, _gen_class} ->
        {:error, :invalid_generic_device_class}

      {:unk, _gen, _spec} ->
        {:error, :invalid_specific_device_class}

      {:error, :unknown_icon_type = reason} ->
        {:error, reason}
    end
  end
end
