defmodule Grizzly.ZWave.SmartStart.MetaExtension.ProductType do
  @moduledoc """
  This Information Type is used to advertise the product type data of a
  supporting node
  """
  @behaviour Grizzly.ZWave.SmartStart.MetaExtension

  alias Grizzly.ZWave.{IconType, DeviceClasses}

  @typedoc """
  The generic and specific device classes are what is advertised in the
  Node Information Frame (NIF)

  The installer icon for the specific device see `Grizzly.IconType` for
  more information
  """
  @type t :: %__MODULE__{
          generic_device_class: atom(),
          specific_device_class: atom(),
          installer_icon: IconType.name()
        }

  defstruct generic_device_class: nil, specific_device_class: nil, installer_icon: nil

  @doc """
  Make a new `ProductType.t()`

  If there is invalid device classes or installer icon type with will return
  `{:error, reason}` where reason is:

  * `:invalid_generic_device_class` - the generic device class could not be
     encoded into its byte representation
  * `:invalid_specific_device_class` - the specific device class could nto be
     encoded into its byte representation
  * `:unknown_icon_type` - the installer icon type cannot be encoded into its
     byte representation
  """
  @spec new(atom(), atom(), IconType.name()) ::
          {:ok, t()}
  def new(generic_device_class, specific_device_class, installer_icon) do
    {:ok,
     %__MODULE__{
       generic_device_class: generic_device_class,
       specific_device_class: specific_device_class,
       installer_icon: installer_icon
     }}
  end

  @doc """
  Make a `ProductType.t()` from a binary string

  According to the specification for this extension the critical bit must not
  be set. If it is then the binary is not consider valid and should be
  ignored.
  """
  @impl true
  @spec from_binary(binary()) :: {:ok, t()} | {:error, :critical_bit_set | :invalid_binary}
  def from_binary(
        <<0::size(7), 0::size(1), 0x04, gen_dev_class, spec_dev_class, installer_icon::size(16)>>
      ) do
    {:ok, installer_icon} = IconType.to_name(installer_icon)
    {:ok, generic_class} = DeviceClasses.generic_device_class_from_byte(gen_dev_class)

    {:ok, spec_class} =
      DeviceClasses.specific_device_class_from_byte(generic_class, spec_dev_class)

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

  def from_binary(_), do: {:error, :invalid_binary}

  @doc """
  Build a binary from a `ProductType.t()`
  """
  @impl true
  @spec to_binary(t()) :: {:ok, binary()}
  def to_binary(%__MODULE__{
        generic_device_class: gdc,
        specific_device_class: sdc,
        installer_icon: icon
      }) do
    gen_byte = DeviceClasses.generic_device_class_to_byte(gdc)
    spec_byte = DeviceClasses.specific_device_class_to_byte(gdc, sdc)
    {:ok, icon_integer} = IconType.to_value(icon)
    {:ok, <<0x00, 0x04, gen_byte, spec_byte, icon_integer::size(16)>>}
  end
end
