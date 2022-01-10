defmodule Grizzly.ZWave.Commands.WindowCoveringSupportedReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.WindowCoveringSupportedReport

  test "creates the command and validates params" do
    params = [
      parameter_names: [
        :out_left_positioned,
        :out_right_positioned,
        :in_left_positioned,
        :in_bottom_positioned,
        :in_top_positioned
      ]
    ]

    {:ok, _command} = WindowCoveringSupportedReport.new(params)
  end

  test "encodes params correctly" do
    params = [
      parameter_names: [
        :out_left_positioned,
        :out_right_positioned,
        :in_left_positioned,
        :in_bottom_positioned,
        :in_top_positioned
      ]
    ]

    {:ok, command} = WindowCoveringSupportedReport.new(params)
    expected_binary = <<0::size(4), 3::size(4), 168, 0, 160>>
    assert expected_binary == WindowCoveringSupportedReport.encode_params(command)
  end

  test "decodes params correctly" do
    binary_params = <<0::size(4), 3::size(4), 168, 0, 160>>
    {:ok, params} = WindowCoveringSupportedReport.decode_params(binary_params)

    assert Enum.sort(Keyword.get(params, :parameter_names)) ==
             Enum.sort([
               :out_left_positioned,
               :out_right_positioned,
               :in_left_positioned,
               :in_bottom_positioned,
               :in_top_positioned
             ])
  end
end
