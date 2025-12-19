defmodule Grizzly.ZWave.Commands.VersionCapabilitiesReport do
  @moduledoc """
  This module implements command VERSION_CAPABILITIES_REPORT of command class
  COMMAND_CLASS_VERSION

  Params: - none -

  """

  @behaviour Grizzly.ZWave.Command

  import Grizzly.ZWave.Encoding

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses.Version

  @type param ::
          {:zwave_software, boolean()} | {:command_class, boolean()} | {:version, boolean()}

  @impl Grizzly.ZWave.Command
  def new(params) do
    command = %Command{
      name: :version_capabilities_report,
      command_byte: 0x16,
      command_class: Version,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl Grizzly.ZWave.Command
  def encode_params(command) do
    zws = Command.param!(command, :zwave_software) |> bool_to_bit()
    cc = Command.param!(command, :command_class) |> bool_to_bit()
    v = Command.param!(command, :version) |> bool_to_bit()

    <<0::5, zws::1, cc::1, v::1>>
  end

  @impl Grizzly.ZWave.Command
  def decode_params(<<_reserved::5, zws::1, cc::1, v::1>>) do
    {:ok,
     [zwave_software: bit_to_bool(zws), command_class: bit_to_bool(cc), version: bit_to_bool(v)]}
  end
end
