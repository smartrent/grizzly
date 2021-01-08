defmodule Grizzly.ZWave.Commands.SceneActuatorConfReportTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Commands.SceneActuatorConfReport

  test "creates the command and validates params" do
    params = [scene_id: 1, dimming_duration: [minutes: 2], level: 90]
    {:ok, _command} = SceneActuatorConfReport.new(params)
  end

  test "encodes params correctly" do
    params = [scene_id: 1, dimming_duration: [minutes: 2], level: 90]
    {:ok, command} = SceneActuatorConfReport.new(params)
    expected_binary = <<1, 90, 0x81>>
    assert expected_binary == SceneActuatorConfReport.encode_params(command)
  end

  test "decodes params correctly" do
    params_binary = <<1, 90, 0x81>>
    {:ok, params} = SceneActuatorConfReport.decode_params(params_binary)
    assert Keyword.get(params, :scene_id) == 1
    assert Keyword.get(params, :level) == 90
    assert Keyword.get(params, :dimming_duration) == [minutes: 2]
  end
end
