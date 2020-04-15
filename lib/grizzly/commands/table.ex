defmodule Grizzly.Commands.Table do
  @moduledoc false

  # look up support for supported command classes and their default Grizzly
  # runtime related options. This where Grizzly and Z-Wave meet in regards to
  # out going commands

  alias Grizzly.CommandHandlers.{AckResponse, WaitReport}

  alias Grizzly.ZWave.Commands.{
    SwitchBinaryGet,
    SwitchBinarySet,
    NodeListGet,
    NodeAdd,
    NodeAddDSKSet,
    NodeAddKeysSet,
    NodeRemove,
    NodeInfoCachedGet
  }

  @doc """
  Look up the Z-Wave command module and default Grizzly command options via the
  command name
  """
  @spec lookup(Grizzly.command()) :: {module(), [Grizzly.command_opt()]}
  def lookup(:switch_binary_get),
    do: {SwitchBinaryGet, handler: {WaitReport, complete_report: :switch_binary_report}}

  def lookup(:switch_binary_set), do: {SwitchBinarySet, handler: AckResponse}

  def lookup(:node_list_get),
    do: {NodeListGet, handler: {WaitReport, complete_report: :node_list_report}}

  def lookup(:node_add), do: {NodeAdd, handler: {WaitReport, complete_report: :node_add_status}}

  def lookup(:node_info_cached_get),
    do: {NodeInfoCachedGet, handler: {WaitReport, complete_report: :node_info_cache_report}}

  def lookup(:node_remove),
    do: {NodeRemove, handler: {WaitReport, complete_report: :node_remove_status}}

  def lookup(:node_add_keys_set), do: {NodeAddKeysSet, handler: AckResponse}
  def lookup(:node_add_dsk_set), do: {NodeAddDSKSet, handler: AckResponse}

  def lookup(_) do
    raise ArgumentError, """
    The command you are trying to send is not supported
    """
  end

  @doc """
  Get the handler spec for the command
  """
  @spec handler(Grizzly.command()) :: module() | {module(), args :: list()}
  def handler(command_name) do
    {_, opts} = lookup(command_name)

    Keyword.fetch!(opts, :handler)
  end
end
