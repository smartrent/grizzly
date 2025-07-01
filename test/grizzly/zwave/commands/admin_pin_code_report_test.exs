defmodule Grizzly.ZWave.Commands.AdminPinCodeReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.AdminPinCodeReport

  test "encodes params correctly" do
    params = [result: :response_to_get, code: "0123456789ABCDEF01234"]
    {:ok, command} = AdminPinCodeReport.new(params)

    assert AdminPinCodeReport.encode_params(command) ==
             <<4::4, 15::4, "0123456789ABCDE">>
  end

  test "decodes params correctly" do
    binary = <<4::4, 15::4, "0123456789ABCDE">>

    assert AdminPinCodeReport.decode_params(binary) ==
             {:ok, [result: :response_to_get, code: "0123456789ABCDE"]}
  end
end
