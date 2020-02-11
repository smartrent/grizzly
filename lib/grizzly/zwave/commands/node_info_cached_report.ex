defmodule Grizzly.ZWave.Commands.NodeInfoCacheReport do
  @moduledoc """
  Report the cached node information

  This command is normally used to respond to the `NodeInfoCacheGet` command

  Params:

  - `:seq_number` - the sequence number of the network command, normally from
    from the `NodeInfoCacheGet` command (required)
  - `:status` - the status fo the node information (required)
  - `:age` - the age of the cache data. A number that is expressed `2 ^ n`
    minutes (required)
  - `:listening?` - if the node is listening node or sleeping node (required)
  - `:command_classes` - a list of command classes (optional default empty
    list)
  - `:basic_device_class` - the basic device class (required)
  - `:generic_device_class` - the generic device class (required)
  """
end
