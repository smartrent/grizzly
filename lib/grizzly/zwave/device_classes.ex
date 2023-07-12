defmodule Grizzly.ZWave.DeviceClasses do
  @moduledoc """
  Z-Wave device classes
  """

  defmodule Generate do
    @moduledoc false

    import Grizzly.ZWave.GeneratedMappings,
      only: [
        basic_device_class_mappings: 0,
        generic_device_class_mappings: 0,
        specific_device_class_mappings: 0
      ]

    defmacro __before_compile__(_) do
      basic_mappings = basic_device_class_mappings()
      generic_mappings = generic_device_class_mappings()
      specific_mappings = specific_device_class_mappings()

      basic_device_class_from_byte =
        for {byte, device_class} <- basic_mappings do
          quote do
            def basic_device_class_from_byte(unquote(byte)), do: {:ok, unquote(device_class)}
          end
        end

      basic_device_class_to_byte =
        for {byte, device_class} <- basic_mappings do
          quote do
            def basic_device_class_to_byte(unquote(device_class)), do: unquote(byte)
          end
        end

      generic_device_class_from_byte =
        for {byte, device_class} <- generic_mappings do
          quote do
            def generic_device_class_from_byte(unquote(byte)), do: {:ok, unquote(device_class)}
          end
        end

      generic_device_class_to_byte =
        for {byte, device_class} <- generic_mappings do
          quote do
            def generic_device_class_to_byte(unquote(device_class)), do: unquote(byte)
          end
        end

      specific_device_class_from_byte =
        for {gen_class, byte, spec_class} <- specific_mappings do
          quote do
            def specific_device_class_from_byte(unquote(gen_class), unquote(byte)),
              do: {:ok, unquote(spec_class)}
          end
        end

      specific_device_class_to_byte =
        for {gen_class, byte, spec_class} <- specific_mappings do
          quote do
            def specific_device_class_to_byte(unquote(gen_class), unquote(spec_class)),
              do: unquote(byte)
          end
        end

      basic_classes_union =
        basic_mappings
        |> Enum.map(&elem(&1, 1))
        |> Enum.reverse()
        |> Enum.reduce(&{:|, [], [&1, &2]})

      generic_classes_union =
        generic_mappings
        |> Enum.map(&elem(&1, 1))
        |> Enum.reverse()
        |> Enum.reduce(&{:|, [], [&1, &2]})

      specific_classes_union =
        specific_mappings
        |> Enum.map(&elem(&1, 2))
        |> Enum.reverse()
        |> Enum.uniq()
        |> Enum.reduce(&{:|, [], [&1, &2]})

      quote do
        @type basic_device_class :: unquote(basic_classes_union)
        @type generic_device_class :: unquote(generic_classes_union)
        @type specific_device_class :: unquote(specific_classes_union)

        @doc """
        Try to make a basic device class from a byte
        """
        @spec basic_device_class_from_byte(byte()) ::
                {:ok, basic_device_class()} | {:ok, :unknown}
        unquote(basic_device_class_from_byte)
        def basic_device_class_from_byte(_byte), do: {:ok, :unknown}

        @doc """
        Make a byte from a device class
        """
        @spec basic_device_class_to_byte(basic_device_class()) :: byte()
        unquote(basic_device_class_to_byte)

        @doc """
        Try to get the generic device class for the byte
        """
        @spec generic_device_class_from_byte(byte()) ::
                {:ok, generic_device_class()} | {:ok, :unknown}
        unquote(generic_device_class_from_byte)
        def generic_device_class_from_byte(_byte), do: {:ok, :unknown}

        @doc """
        Turn the generic device class into a byte
        """
        @spec generic_device_class_to_byte(generic_device_class()) :: byte()
        unquote(generic_device_class_to_byte)

        @doc """
        Try to get the specific device class from the byte given the generic device class
        """
        @spec specific_device_class_from_byte(generic_device_class(), byte()) ::
                {:ok, specific_device_class()} | {:ok, :unknown}
        unquote(specific_device_class_from_byte)
        def specific_device_class_from_byte(_, _byte), do: {:ok, :unknown}

        @doc """
        Make the specific device class into a byte
        """
        @spec specific_device_class_to_byte(generic_device_class(), specific_device_class()) ::
                byte()
        unquote(specific_device_class_to_byte)
      end
    end
  end

  @before_compile Generate
end
