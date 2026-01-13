defmodule Grizzly.ZWave.Commands.VersionCapabilitiesReport do
  @moduledoc """
  This module implements command VERSION_CAPABILITIES_REPORT of command class
  COMMAND_CLASS_VERSION

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command

  @type param ::
          {:zwave_software, boolean()} | {:command_class, boolean()} | {:version, boolean()}

  @impl Grizzly.ZWave.Command
  def encode_params(_spec, command) do
    zws = Command.param!(command, :zwave_software) |> bool_to_bit()
    cc = Command.param!(command, :command_class) |> bool_to_bit()
    v = Command.param!(command, :version) |> bool_to_bit()

    <<0::5, zws::1, cc::1, v::1>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(_spec, <<_reserved::5, zws::1, cc::1, v::1>>) do
    {:ok,
     [zwave_software: bit_to_bool(zws), command_class: bit_to_bool(cc), version: bit_to_bool(v)]}
  end
end
