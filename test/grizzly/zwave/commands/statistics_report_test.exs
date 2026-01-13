defmodule Grizzly.ZWave.Commands.StatisticsReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands
  alias Grizzly.ZWave.Commands.StatisticsReport

  test "creates the command and validates params" do
    statistics = [
      route_changes: 2,
      transmission_count: 10,
      neighbors: [
        [node_id: 5, repeater?: true, speed: [:"100kbit/s"]],
        [node_id: 6, repeater?: false, speed: [:"40kbit/s"]]
      ],
      packet_error_count: 5,
      sum_of_transmission_times: 12,
      sum_of_transmission_times_squared: 144
    ]

    params = [node_id: 4, statistics: statistics]
    {:ok, _command} = Commands.create(:statistics_report, params)
  end

  test "encodes params correctly" do
    statistics = [
      route_changes: 2,
      transmission_count: 10,
      neighbors: [
        [node_id: 5, repeater?: true, speed: [:"100kbit/s"]],
        [node_id: 6, repeater?: false, speed: [:"40kbit/s"]]
      ],
      packet_error_count: 5,
      sum_of_transmission_times: 12,
      sum_of_transmission_times_squared: 144
    ]

    params = [node_id: 4, statistics: statistics]
    {:ok, command} = Commands.create(:statistics_report, params)
    route_change = <<0x00, 0x01, 0x02>>
    transmission_count = <<0x01, 0x01, 0x0A>>

    neighbors =
      <<0x02, 0x04>> <>
        <<0x05, 0x01::1, 0x00::2, 0x04::5>> <>
        <<0x06, 0x00::1, 0x00::2, 0x02::5>>

    packet_error_count = <<0x03, 0x01, 0x05>>
    sum_of_transmission_times = <<0x04, 0x04, 12::32>>
    sum_of_transmission_times_squared = <<0x05, 0x04, 144::32>>

    expected_binary =
      <<0x04>> <>
        route_change <>
        transmission_count <>
        neighbors <>
        packet_error_count <>
        sum_of_transmission_times <> sum_of_transmission_times_squared

    assert expected_binary == StatisticsReport.encode_params(nil, command)
  end

  test "decodes params correctly" do
    route_change = <<0x00, 0x01, 0x02>>
    transmission_count = <<0x01, 0x01, 0x0A>>

    neighbors =
      <<0x02, 0x04>> <>
        <<0x05, 0x01::1, 0x00::2, 0x03::5>> <>
        <<0x06, 0x00::1, 0x00::2, 0x08::5>>

    sum_of_transmission_times = <<0x04, 0x04, 12::32>>
    sum_of_transmission_times_squared = <<0x05, 0x04, 144::32>>

    params_binary =
      <<0x04>> <>
        route_change <>
        transmission_count <>
        neighbors <>
        sum_of_transmission_times <> sum_of_transmission_times_squared

    {:ok, params} = StatisticsReport.decode_params(nil, params_binary)
    assert Keyword.get(params, :node_id) == 4
    statistics = Keyword.get(params, :statistics)
    assert Keyword.get(statistics, :route_changes) == 2
    assert Keyword.get(statistics, :transmission_count) == 10
    [n1, n2] = Keyword.get(statistics, :neighbors)
    assert Keyword.get(n1, :node_id) == 5
    assert Keyword.get(n1, :repeater?) == true
    assert Keyword.get(n1, :speed) == [:"9.6kbit/s", :"40kbit/s"]
    assert Keyword.get(n2, :node_id) == 6
    assert Keyword.get(n2, :repeater?) == false
    assert Keyword.get(n2, :speed) == []
  end
end
