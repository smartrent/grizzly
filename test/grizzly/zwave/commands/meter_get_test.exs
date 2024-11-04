defmodule Grizzly.ZWave.Commands.MeterGetTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.MeterGet

  test "creates the command and validates params" do
    params = []
    {:ok, _command} = MeterGet.new(params)
  end

  test "encodes params correctly" do
    # v1
    params = []
    {:ok, command} = MeterGet.new(params)
    assert MeterGet.encode_params(command) == <<>>

    # v2-3
    params = [scale: :kwh]
    {:ok, command} = MeterGet.new(params)
    assert MeterGet.encode_params(command) == <<0::2, 0::3, 0::3>>

    # v4-6
    params = [scale: :kwh, rate_type: :default]
    {:ok, command} = MeterGet.new(params)
    assert MeterGet.encode_params(command) == <<0::2, 0::3, 0::3, 0>>

    # v4-6
    params = [scale: :kwh, rate_type: :import]
    {:ok, command} = MeterGet.new(params)
    assert MeterGet.encode_params(command) == <<1::2, 0::3, 0::3, 0>>

    # v4-6
    params = [scale: :kwh, rate_type: :import_export]
    {:ok, command} = MeterGet.new(params)
    assert MeterGet.encode_params(command) == <<3::2, 0::3, 0::3, 0>>

    # v4-6
    params = [scale: :pulse_count, rate_type: :import_export]
    {:ok, command} = MeterGet.new(params)
    assert MeterGet.encode_params(command) == <<3::2, 3::3, 0::3, 0>>

    # v4-6
    params = [scale: :kvarh, rate_type: :import_export]
    {:ok, command} = MeterGet.new(params)
    assert MeterGet.encode_params(command) == <<3::2, 7::3, 0::3, 1>>

    # v4-6
    params = [scale: :kvar]
    {:ok, command} = MeterGet.new(params)
    assert MeterGet.encode_params(command) == <<0::2, 7::3, 0::3, 0>>

    # re-encode something we decoded without knowing the meter type
    params = [scale: 7, scale2: 1, rate_type: :import_export]
    {:ok, command} = MeterGet.new(params)
    assert MeterGet.encode_params(command) == <<3::2, 7::3, 0::3, 1>>
  end

  test "decodes params correctly" do
    # v1
    binary = <<>>
    assert {:ok, params} = MeterGet.decode_params(binary, :electric)
    assert params == [scale: nil, rate_type: nil]

    # v2-3
    binary = <<0::2, 0::3, 0::3>>
    assert {:ok, params} = MeterGet.decode_params(binary, :electric)
    assert params == [scale: :kwh, rate_type: nil]

    # v4-6
    binary = <<0::2, 0::3, 0::3, 0>>
    assert {:ok, params} = MeterGet.decode_params(binary, :electric)
    assert params == [scale: :kwh, rate_type: :default]

    # v4-6
    binary = <<1::2, 0::3, 0::3, 0>>
    assert {:ok, params} = MeterGet.decode_params(binary, :electric)
    assert params == [scale: :kwh, rate_type: :import]

    # v4-6
    binary = <<3::2, 0::3, 0::3, 0>>
    assert {:ok, params} = MeterGet.decode_params(binary, :electric)
    assert params == [scale: :kwh, rate_type: :import_export]

    # v4-6
    binary = <<3::2, 3::3, 0::3, 0>>
    assert {:ok, params} = MeterGet.decode_params(binary, :electric)
    assert params == [scale: :pulse_count, rate_type: :import_export]

    # v4-6
    binary = <<3::2, 7::3, 0::3, 1>>
    assert {:ok, params} = MeterGet.decode_params(binary, :electric)
    assert params == [scale: :kvarh, rate_type: :import_export]

    # v4-6
    binary = <<0::2, 7::3, 0::3, 0>>
    assert {:ok, params} = MeterGet.decode_params(binary, :electric)
    assert params == [scale: :kvar, rate_type: :default]
  end
end
