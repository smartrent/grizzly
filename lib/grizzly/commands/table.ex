defmodule Grizzly.Commands.Table do
  @moduledoc false

  # look up support for supported command classes and their default Grizzly
  # runtime related options. This where Grizzly and Z-Wave meet in regards to
  # out going commands

  defmodule Generate do
    @moduledoc false
    alias Grizzly.CommandHandlers.{AckResponse, WaitReport, AggregateReport}

    alias Grizzly.ZWave.Commands

    @table [
      {:default_set,
       {Commands.DefaultSet, handler: {WaitReport, complete_report: :default_set_complete}}},
      {:switch_binary_get,
       {Commands.SwitchBinaryGet, handler: {WaitReport, complete_report: :switch_binary_report}}},
      {:switch_binary_set, {Commands.SwitchBinarySet, handler: AckResponse}},
      {:node_list_get,
       {Commands.NodeListGet, handler: {WaitReport, complete_report: :node_list_report}}},
      {:node_add, {Commands.NodeAdd, handler: {WaitReport, complete_report: :node_add_status}}},
      {:node_info_cached_get,
       {Commands.NodeInfoCachedGet,
        handler: {WaitReport, complete_report: :node_info_cache_report}}},
      {:node_remove,
       {Commands.NodeRemove, handler: {WaitReport, complete_report: :node_remove_status}}},
      {:node_add_keys_set, {Commands.NodeAddKeysSet, handler: AckResponse}},
      {:node_add_dsk_set, {Commands.NodeAddDSKSet, handler: AckResponse}},
      {:association_set, {Commands.AssociationSet, handler: AckResponse}},
      {:association_get,
       {Commands.AssociationGet,
        handler: {AggregateReport, complete_report: :association_report, aggregate_param: :nodes}}},
      {:keep_alive, {Commands.ZIPKeepAlive, handler: AckResponse}}
    ]

    defmacro __before_compile__(_) do
      lookup =
        for {command_class, spec} <- @table do
          quote location: :keep do
            def lookup(unquote(command_class)), do: unquote(spec)
          end
        end

      quote location: :keep do
        @doc """
        Look up the Z-Wave command module and default Grizzly command options via the
        command name
        """
        @spec lookup(Grizzly.command()) :: {module(), [Grizzly.command_opt()]}
        unquote(lookup)

        def lookup(_) do
          raise ArgumentError, """
          The command you are trying to send is not supported
          """
        end
      end
    end
  end

  @before_compile Generate

  @doc """
  Get the handler spec for the command
  """
  @spec handler(Grizzly.command()) :: module() | {module(), args :: list()}
  def handler(command_name) do
    {_, opts} = lookup(command_name)

    Keyword.fetch!(opts, :handler)
  end
end
