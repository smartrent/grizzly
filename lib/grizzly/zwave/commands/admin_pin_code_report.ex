defmodule Grizzly.ZWave.Commands.AdminPinCodeReport do
  @moduledoc """
  AdminPinCodeReport is used to report the admin code currently set at the sending node.

  ## Parameters

  * `:result` - the result of the operation (required)
  * `:code` - the admin code (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type result ::
          :modified
          | :unmodified
          | :response_to_get
          | :duplicate
          | :manufacturer_security_rules
          | :admin_code_not_supported
          | :deactivation_not_supported
          | :unspecified_error

  @type param :: {:result, result()} | {:code, binary()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    result = Command.param!(command, :result)
    code = Command.param!(command, :code) |> binary_slice(0, 15)
    <<encode_result(result)::4, byte_size(code)::4, code::binary>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<result::4, length::4, code::binary-size(length)>>) do
    {:ok,
     [
       result: decode_result(result),
       code: code
     ]}
  end

  defp encode_result(:modified), do: 0x01
  defp encode_result(:unmodified), do: 0x03
  defp encode_result(:response_to_get), do: 0x04
  defp encode_result(:duplicate), do: 0x07
  defp encode_result(:manufacturer_security_rules), do: 0x08
  defp encode_result(:admin_code_not_supported), do: 0x0D
  defp encode_result(:deactivation_not_supported), do: 0x0E
  defp encode_result(:unspecified_error), do: 0x0F

  defp decode_result(0x01), do: :modified
  defp decode_result(0x03), do: :unmodified
  defp decode_result(0x04), do: :response_to_get
  defp decode_result(0x07), do: :duplicate
  defp decode_result(0x08), do: :manufacturer_security_rules
  defp decode_result(0x0D), do: :admin_code_not_supported
  defp decode_result(0x0E), do: :deactivation_not_supported
  defp decode_result(0x0F), do: :unspecified_error
  defp decode_result(_), do: :unknown
end
