defmodule Grizzly.Storage do
  @moduledoc """
  Persistent storage for device information and other Grizzly internals.
  """

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{Command, CommandClasses, DeviceClasses, DSK, Security}
  alias Grizzly.ZWave.CommandClasses.NetworkManagementInclusion, as: NMI

  @typedoc """
  See `t:PropertyTable.property/0`.
  """
  @type key :: PropertyTable.property()

  @typedoc """
  See `t:PropertyTable.value/0`.
  """
  @type value :: PropertyTable.value()

  @typedoc """
  See `t:PropertyTable.pattern/0`.
  """
  @type pattern :: PropertyTable.pattern()

  @type put_node_info_opt() :: {:overwrite_command_classes, boolean()}

  @type node_info() :: %{
          listening?: boolean(),
          basic_device_class: DeviceClasses.basic_device_class(),
          generic_device_class: DeviceClasses.generic_device_class(),
          specific_device_class: DeviceClasses.specific_device_class(),
          command_classes: CommandClasses.command_class_list()
        }

  @type node_inclusion_info() :: %{
          status: NMI.node_add_status(),
          granted_keys: [Security.key()],
          kex_fail_type: Security.key_exchange_fail_type() | nil,
          smartstart?: boolean()
        }

  @doc """
  Returns a child spec to start the storage process under a supervisor.
  See `Supervisor`.
  """
  @spec child_spec(PropertyTable.options()) :: Supervisor.child_spec()
  def child_spec(opts) do
    opts
    |> Keyword.merge(name: __MODULE__)
    |> PropertyTable.child_spec()
  end

  @doc """
  Puts a key-value pair into storage using the configured adapter.
  """
  @spec put(key(), value()) :: :ok
  def put(key, value) do
    {adapter, arg} = adapter()
    adapter.put(arg, key, value)
  end

  @doc """
  Puts multiple key-value pairs into storage using the configured adapter.
  """
  @spec put_many([{key(), value()}]) :: :ok
  def put_many(properties) do
    {adapter, arg} = adapter()
    adapter.put_many(arg, properties)
  end

  @doc """
  Get a value from storage by key using the configured adapter.
  """
  @spec get(key()) :: value()
  def get(key) do
    {adapter, arg} = adapter()
    adapter.get(arg, key)
  end

  @doc """
  Match keys in storage against a pattern using the configured adapter.
  """
  @spec match(pattern()) :: [{key(), value()}]
  def match(pattern) do
    {adapter, arg} = adapter()
    adapter.match(arg, pattern)
  end

  @doc """
  Delete keys matching a pattern using the configured adapter.
  """
  @spec delete_matches(pattern()) :: :ok
  def delete_matches(pattern) do
    {adapter, arg} = adapter()
    adapter.delete_matches(arg, pattern)
  end

  @doc """
  Delete everything from storage.
  """
  @spec delete_all() :: :ok
  def delete_all(), do: delete_matches([])

  @doc """
  Stores information about a node's inclusion process.
  """
  @spec put_node_inclusion_info(ZWave.node_id(), node_inclusion_info()) :: :ok
  def put_node_inclusion_info(
        node_id,
        %{status: _, granted_keys: _, kex_fail_type: _, smartstart?: _} = info
      ) do
    put(node_key(node_id, "inclusion_info"), info)
  end

  @doc """
  Retrieves information about a node's inclusion process.
  """
  @spec get_node_inclusion_info(ZWave.node_id()) :: node_inclusion_info() | nil
  def get_node_inclusion_info(node_id) do
    get(node_key(node_id, "inclusion_info"))
  end

  @doc """
  Stores node information.

  By default, command classes are merged using `CommandClasses.merge/2` to prevent
  loss of data due to Z/IP Gateway quirks. To force the use of the new command class
  list, use the `:overwrite_command_classes` option.
  """
  @spec put_node_info(ZWave.node_id(), Command.t() | node_info(), [put_node_info_opt()]) :: :ok
  def put_node_info(node_id, info, opts \\ [])

  def put_node_info(
        node_id,
        %{
          listening?: _,
          basic_device_class: _,
          generic_device_class: _,
          specific_device_class: _,
          command_classes: _
        } = info,
        opts
      ) do
    info =
      if Keyword.get(opts, :overwrite_command_classes) == true do
        info
      else
        Map.update(info, :command_classes, info.command_classes, fn current_cc_list ->
          CommandClasses.merge(current_cc_list, info.command_classes)
        end)
      end

    put(node_key(node_id, "info"), info)
  end

  def put_node_info(node_id, %Command{name: :node_info_cached_report} = cmd, opts) do
    info = %{
      listening?: Command.param!(cmd, :listening?),
      basic_device_class: Command.param!(cmd, :basic_device_class),
      generic_device_class: Command.param!(cmd, :generic_device_class),
      specific_device_class: Command.param!(cmd, :specific_device_class),
      command_classes: Command.param!(cmd, :command_classes)
    }

    put_node_info(node_id, info, opts)
  end

  @doc """
  Retrieves a node's basic info.
  """
  @spec get_node_info(ZWave.node_id()) :: node_info() | nil
  def get_node_info(node_id) do
    get(node_key(node_id, "info"))
  end

  @doc """
  Store a node's DSK.
  """
  @spec put_node_dsk(ZWave.node_id(), DSK.t()) :: :ok
  def put_node_dsk(node_id, %DSK{} = dsk) do
    put(node_key(node_id, "dsk"), DSK.to_string(dsk))
  end

  @doc """
  Returns a node's stored DSK.
  """
  @spec get_node_dsk(ZWave.node_id()) :: DSK.t() | nil
  def get_node_dsk(node_id) do
    case get(node_key(node_id, "dsk")) do
      nil -> nil
      dsk_string -> DSK.parse!(dsk_string)
    end
  end

  @doc """
  Stores a node's wakeup interval in seconds.
  """
  @spec put_node_wakeup_interval(ZWave.node_id(), non_neg_integer()) :: :ok
  def put_node_wakeup_interval(node_id, interval) do
    put(node_key(node_id, ["wakeup_interval"]), interval)
  end

  @doc """
  Returns the node's wakeup interval in seconds.
  """
  @spec get_node_wakeup_interval(ZWave.node_id()) :: non_neg_integer() | nil
  def get_node_wakeup_interval(node_id) do
    get(node_key(node_id, ["wakeup_interval"]))
  end

  @doc """
  Stores a node's last awake time.
  """
  @spec put_node_last_awake(ZWave.node_id(), DateTime.t()) :: :ok
  def put_node_last_awake(node_id, last_awake) do
    put(node_key(node_id, ["last_awake"]), last_awake)
  end

  @doc """
  Retrieves a node's last awake time.
  """
  @spec get_node_last_awake(ZWave.node_id()) :: DateTime.t() | nil
  def get_node_last_awake(node_id) do
    get(node_key(node_id, ["last_awake"]))
  end

  @doc """
  Stores a node's command class version.
  """
  @spec put_node_command_class_version(ZWave.node_id(), atom(), pos_integer()) :: :ok
  def put_node_command_class_version(node_id, command_class, version) do
    put(node_key(node_id, ["command_classes", "#{command_class}", "version"]), version)
  end

  @doc """
  Retrieves a node's command class version.
  """
  @spec get_node_command_class_version(ZWave.node_id(), atom()) :: pos_integer() | nil
  def get_node_command_class_version(node_id, command_class) do
    get(node_key(node_id, ["command_classes", "#{command_class}", "version"]))
  end

  defp node_key(:gateway, rest), do: ["node", "1" | List.wrap(rest)]
  defp node_key(node_id, rest), do: ["node", "#{node_id}" | List.wrap(rest)]

  defp adapter() do
    {_adapter, _arg} = Grizzly.options().storage_adapter
  end
end
