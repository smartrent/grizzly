defmodule Grizzly.ZWave.Commands.AdminPinCodeReport do
  @moduledoc """
  AdminPinCodeReport is used to report the admin code currently set at the sending node.

  ## Parameters

  * `:result` - the result of the operation (required)
  * `:code` - the admin code (required)
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.UserCredential
  alias Grizzly.ZWave.DecodeError

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
  @spec new([param()]) :: {:ok, Command.t()}
  def new(params) do
    command = %Command{
      name: :admin_pin_code_report,
      command_byte: 0x1C,
      command_class: UserCredential,
      params: params
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  @spec encode_params(Command.t()) :: binary()
  def encode_params(command) do
    result = Command.param!(command, :result)
    code = Command.param!(command, :code) |> binary_slice(0, 15)
    <<encode_result(result)::4, byte_size(code)::4, code::binary>>
  end

  @impl Grizzly.ZWave.Command
  @spec decode_params(binary()) :: {:ok, [param()]} | {:error, DecodeError.t()}
  def decode_params(<<result::4, length::4, code::binary-size(length)>>) do
    {:ok,
     [
       result: decode_result(result),
       code: code
     ]}
  end

  def encode_result(:modified), do: 0x01
  def encode_result(:unmodified), do: 0x03
  def encode_result(:response_to_get), do: 0x04
  def encode_result(:duplicate), do: 0x07
  def encode_result(:manufacturer_security_rules), do: 0x08
  def encode_result(:admin_code_not_supported), do: 0x0D
  def encode_result(:deactivation_not_supported), do: 0x0E
  def encode_result(:unspecified_error), do: 0x0F

  def decode_result(0x01), do: :modified
  def decode_result(0x03), do: :unmodified
  def decode_result(0x04), do: :response_to_get
  def decode_result(0x07), do: :duplicate
  def decode_result(0x08), do: :manufacturer_security_rules
  def decode_result(0x0D), do: :admin_code_not_supported
  def decode_result(0x0E), do: :deactivation_not_supported
  def decode_result(0x0F), do: :unspecified_error
  def decode_result(_), do: :unknown
end
