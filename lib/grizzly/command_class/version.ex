defmodule Grizzly.CommandClass.Version do
  @moduledoc """
  Helpers for working with the command class VERSION
  """

  alias Grizzly.CommandClass.Mappings
  require Logger

  @type library_type ::
          :static_controller
          | :controller
          | :enhanced_slave
          | :slave
          | :installer
          | :routing_slave
          | :bridge_controller
          | :device_under_test
          | :av_remote
          | :av_device

  @type version_report :: %{
          protocol_library: library_type(),
          protocol_version: String.t(),
          firmware_version: String.t()
        }

  @doc """
  Decode version report data
  """
  @spec decode_report_data(<<_::16>>) :: %{command_class: atom, version: byte}
  def decode_report_data(<<command_class_byte, version>>) do
    command_class =
      case Mappings.from_byte(command_class_byte) do
        {:unk, _} -> :invalid
        command_class -> command_class
      end

    %{
      command_class: command_class,
      version: version
    }
  end

  @spec decode_version_report(binary()) ::
          {:ok, version_report()} | {:error, :invalid_version_report, binary()}
  def decode_version_report(
        <<protocol_library, protocol_version, protocol_sub_version, firmware_version,
          firmware_sub_version, _::binary>> = binary
      ) do
    with {:ok, library_type} <- decode_library_type(protocol_library) do
      {:ok,
       %{
         protocol_library: library_type,
         protocol_version: "#{protocol_version}.#{protocol_sub_version}",
         firmware_version: "#{firmware_version}.#{firmware_sub_version}"
       }}
    else
      {:error, :invalid_library_type, library_type} ->
        _ = Logger.warn("Invalid library type: #{inspect(library_type)}")
        {:error, :invalid_version_report, binary}
    end
  end

  def decode_version_report(binary), do: {:error, :invalid_version_report, binary}

  @doc """
  Encode command class
  """
  @spec encode_command_class(Mappings.command_class_name()) ::
          {:ok, byte} | {:error, :invalid_arg, Mappings.command_class_name()}
  def encode_command_class(command_class) do
    case Mappings.to_byte(command_class) do
      {:unk, _} ->
        _ = Logger.warn("Unknown command class #{inspect(command_class)}")
        {:error, :invalid_arg, command_class}

      byte ->
        {:ok, byte}
    end
  end

  @doc """
  Decode a byte into a library type
  """
  @spec decode_library_type(byte()) ::
          {:ok, library_type()} | {:error, :invalid_library_type, byte()}
  def decode_library_type(0x01), do: {:ok, :static_controller}
  def decode_library_type(0x02), do: {:ok, :controller}
  def decode_library_type(0x03), do: {:ok, :enhanced_slave}
  def decode_library_type(0x04), do: {:ok, :slave}
  def decode_library_type(0x05), do: {:ok, :installer}
  def decode_library_type(0x06), do: {:ok, :routing_slave}
  def decode_library_type(0x07), do: {:ok, :bridge_controller}
  def decode_library_type(0x08), do: {:ok, :device_under_test}
  def decode_library_type(0x0A), do: {:ok, :av_remote}
  def decode_library_type(0x0B), do: {:ok, :av_device}
  def decode_library_type(byte), do: {:error, :invalid_library_type, byte}
end
