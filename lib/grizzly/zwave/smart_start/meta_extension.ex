defmodule Grizzly.ZWave.SmartStart.MetaExtension do
  @moduledoc """
  Meta Extensions for SmartStart devices for QR codes and node provisioning
  list
  """

  alias Grizzly.ZWave
  alias Grizzly.ZWave.{DeviceClasses, IconType, Security}
  alias Grizzly.ZWave.SmartStart.MetaExtension.UUID16

  import Bitwise

  @advanced_joining 0x35
  @bootstrapping_mode 0x36
  @location_information 0x33
  @max_inclusion_request_interval 0x02
  @name_information 0x32
  @network_status 0x37
  @product_id 0x01
  @product_type 0x00
  @smart_start_inclusion_setting 0x34
  @uuid16 0x03

  @typedoc """
  Unsigned 16 bit integer
  """
  @type unit_16() :: char()

  @typedoc """
  The mode to use when including the node advertised in the provisioning list

  - `:security_2` - the node must be manually set to learn mode and follow the
    S2 bootstrapping instructions
  - `:smart_start` - the node will use S2 bootstrapping automatically using the
    SmartStart functionality
  - `:long_range` - included the device using the Z-Waver long range protocol.
    If no keys are granted in the `:advanced_joining` extension this inclusion
    will fail.
  """
  @type bootstrapping_mode() :: :security_2 | :smart_start | :long_range

  @typedoc """
  The different network statuses are:

  - `:not_in_network` - the node in the provisioning list is not included in
    the network
  - `:included` - the node in the provisioning list is included in the network
    and is functional
  - `:failing` - the node in the provisioning list is included in the network
    but is now marked as failing
  """
  @type network_status() :: :pending | :passive | :ignored

  @typedoc """
  Id of the manufacturer for the product id extension
  """
  @type manufacturer_id() :: unit_16()

  @typedoc """
  Id of the product produced by the manufacturer for the product id extension
  """
  @type product_id() :: unit_16()

  @typedoc """
  Type of product produced by the manufacturer for the product id extension
  """
  @type product_type() :: unit_16()

  @typedoc """
  Version of the application in a string format of "Major.Minor"
  """
  @type application_version() :: binary()

  @type product_id_values() ::
          {manufacturer_id(), product_id(), product_type(), application_version()}

  @typedoc """
  The interval (in seconds) must be in the range of 640..12672 inclusive, and
  has to be in steps of 128 seconds.

  So after 640 the next valid interval is `640 + 128` which is `768` seconds.

  See `SDS13944 Node Provisioning Information Type Registry.pdf` section
  `3.1.2.3` for more information.
  """
  @type inclusion_interval() :: 640..12672

  @typedoc """
  The location string cannot contain underscores and cannot end with a dash.

  The location string can contain a period (.) but a sublocation cannot end a
  dash. For example:

  ```
  123.123-.123
  ```

  The above location invalid. To make it valid remove the `-` before `.`.

  A node's location cannot be more than 62 bytes.
  """
  @type information_location() :: binary()

  @typedoc """
  The name string cannot contain underscores and cannot end with a dash.

  A node's name cannot be more than 62 bytes.
  """
  @type information_name() :: binary()

  @typedoc """
  Generic Device Class for the product type extension
  """
  @type generic_device_class() :: atom()

  @typedoc """
  Specific Device Class for the product type extension
  """
  @type specific_device_class() :: atom()

  @typedoc """
  Installer icon for the product type extension
  """
  @type installer_icon_type() :: IconType.name()

  @type product_type_values() ::
          {generic_device_class(), specific_device_class(), installer_icon_type()}

  @typedoc """
  Settings for the smart start inclusion setting extension

  * `:pending` - the node will be added to the network when it issues SmartStart
    inclusion requests.
  * `:passive` - this node is unlikely to issues a SmartStart inclusion request
    and SmartStart inclusion requests will be ignored from this node by the
    Z/IP Gateway. All nodes in the list with this setting must be updated to
    `:pending` when Provisioning List Iteration Get command is issued.
  * `:ignored` - All SmartStart inclusion request are ignored from this node
    until updated via Z/IP Client (Grizzly) or a controlling node.
  """
  @type inclusion_setting() :: :pending | :passive | :ignored

  @typedoc """
  Meta extension for SmartStart devices

  * `:advanced_joining` - used to specify which S2 security keys to grant
    during S2 inclusion
  * `:bootstrapping_mode` - used to specify the bootstrapping mode the including
    node must join with
  * `:location_information` - used to advertise the location assigned to the node
  * `:max_inclusion_request_interval` - used to advertise if a power constrained
    smart start node will issue an inclusion request at a higher interval than
    the default 512 seconds
  * `:name_information` - used to advertise the name of the node
  * `:network_status` - used to advertise if the node is in the network and its
    node id
  * `:product_id` - used to advertise product identifying data
  * `:product_type` - used to advertise the product type data
  * `:smart_start_inclusion_setting` - used to advertise the smart start
    inclusion setting
  * `:uuid16` - used to advertise the 16 byte manufacturer-defined information
    that is unique to the that device
  * `:unknown` - sometimes new extensions are released without first class
    support, so this extension is used for those extensions that still need to
    be supported in this library
  """
  @type extension() ::
          {:advanced_joining, [Security.key()]}
          | {:bootstrapping_mode, bootstrapping_mode()}
          | {:location_information, information_location()}
          | {:max_inclusion_request_interval, inclusion_interval()}
          | {:name_information, information_name()}
          | {:network_status, {ZWave.node_id(), atom()}}
          | {:product_id, product_id_values()}
          | {:product_type, product_type_values()}
          | {:smart_start_inclusion_setting, inclusion_setting()}
          | {:uuid16, UUID16.t()}
          | {:unknown, binary()}

  @doc """
  Encode an extension into a binary
  """
  @spec encode(extension()) :: binary()
  def encode(extension) do
    IO.iodata_to_binary(encode_extension(extension))
  end

  defp encode_extension({:advanced_joining, keys}) do
    keys_byte =
      Enum.reduce(keys, 0, fn
        :s2_unauthenticated, byte -> byte ||| 0x01
        :s2_authenticated, byte -> byte ||| 0x02
        :s2_access_control, byte -> byte ||| 0x04
        :s0, byte -> byte ||| 0x40
        _, byte -> byte
      end)

    [set_circuital_bit(@advanced_joining, 1), 0x01, keys_byte]
  end

  defp encode_extension({:bootstrapping_mode, mode}) do
    mode =
      case mode do
        :security_2 -> 0x00
        :smart_start -> 0x01
        :long_range -> 0x02
      end

    [set_circuital_bit(@bootstrapping_mode, 1), 0x01, mode]
  end

  defp encode_extension({:location_information, location}) do
    location =
      location
      |> String.codepoints()
      |> :erlang.list_to_binary()

    [set_circuital_bit(@location_information, 0), byte_size(location), location]
  end

  defp encode_extension({:max_inclusion_request_interval, interval}) do
    interval = Integer.floor_div(interval - 640, 128)

    [set_circuital_bit(@max_inclusion_request_interval, 0), 0x01, interval]
  end

  defp encode_extension({:name_information, name}) do
    name =
      name
      |> String.codepoints()
      |> Enum.reduce([], fn
        ".", nl ->
          nl ++ ["\\", "."]

        c, nl ->
          nl ++ [c]
      end)

    [set_circuital_bit(@name_information, 0), length(name), name]
  end

  # Encodes for Long Range not enabled
  defp encode_extension({:network_status, {node_id, status}}) do
    status =
      case status do
        :not_in_network -> 0x00
        :included -> 0x01
        :failing -> 0x02
      end

    [set_circuital_bit(@network_status, 0), 0x02, node_id, status]
  end

  defp encode_extension({:product_id, {manu_id, prod_id, prod_type, version}}) do
    {:ok, version} = Version.parse(version <> ".0")

    [
      set_circuital_bit(@product_id, 0),
      0x08,
      <<manu_id::16>>,
      <<prod_id::16>>,
      <<prod_type::16>>,
      version.major,
      version.minor
    ]
  end

  defp encode_extension({:product_type, {gen_class, spec_class, icon_name}}) do
    gen_byte = DeviceClasses.generic_device_class_to_byte(gen_class)

    spec_byte =
      DeviceClasses.specific_device_class_to_byte(
        gen_class,
        spec_class
      )

    {:ok, icon_integer} = IconType.to_value(icon_name)

    [set_circuital_bit(@product_type, 0), 0x04, gen_byte, spec_byte, <<icon_integer::16>>]
  end

  defp encode_extension({:smart_start_inclusion_setting, setting}) do
    setting =
      case setting do
        :pending -> 0x00
        :passive -> 0x02
        :ignored -> 0x03
      end

    [set_circuital_bit(@smart_start_inclusion_setting, 1), 0x01, setting]
  end

  defp encode_extension({:uuid16, uuid16}) do
    [UUID16.encode(uuid16)]
  end

  defp encode_extension({:unknown, binary}) do
    [binary]
  end

  @doc """
  Parse the binary into the list of extensions
  """
  @spec parse(binary()) :: [extension()]
  def parse(binary) do
    do_parse(binary, [])
  end

  defp do_parse(<<>>, extensions) do
    Enum.reverse(extensions)
  end

  defp do_parse(<<@advanced_joining::7, 1::1, 0x01, keys, rest::binary>>, extensions) do
    ext = {:advanced_joining, unmask_keys(keys)}

    do_parse(rest, [ext | extensions])
  end

  defp do_parse(
         <<@bootstrapping_mode::7, 1::1, 0x01, mode, rest::binary>>,
         extensions
       ) do
    mode =
      case mode do
        0x00 -> :security_2
        0x01 -> :smart_start
        0x02 -> :long_range
      end

    ext = {:bootstrapping_mode, mode}

    do_parse(rest, [ext | extensions])
  end

  defp do_parse(
         <<@location_information::7, 0::1, len, location::binary-size(len)-unit(8),
           rest::binary>>,
         extensions
       ) do
    ext = {:location_information, to_string(location)}

    do_parse(rest, [ext | extensions])
  end

  defp do_parse(
         <<@max_inclusion_request_interval::7, 0::1, 0x01, interval, rest::binary>>,
         extensions
       ) do
    steps = interval - 5
    interval = 640 + steps * 128

    ext = {:max_inclusion_request_interval, interval}

    do_parse(rest, [ext | extensions])
  end

  defp do_parse(
         <<@name_information::7, 0::1, len, name::binary-size(len)-unit(8), rest::binary>>,
         extensions
       ) do
    name =
      name
      |> to_string()
      |> String.replace("\\", "")

    ext = {:name_information, name}

    do_parse(rest, [ext | extensions])
  end

  # When Long Range is enabled
  defp do_parse(
         <<@network_status::7, 0::1, 0x04, node_id, status_byte, _long_range_node_id::16,
           rest::binary>>,
         extensions
       ) do
    status = decode_status(status_byte)

    ext = {:network_status, {node_id, status}}

    do_parse(rest, [ext | extensions])
  end

  # When Long Range is NOT enabled
  defp do_parse(
         <<@network_status::7, 0::1, 0x02, node_id, status_byte, rest::binary>>,
         extensions
       ) do
    status = decode_status(status_byte)

    ext = {:network_status, {node_id, status}}

    do_parse(rest, [ext | extensions])
  end

  defp do_parse(
         <<@product_id::7, 0::1, 0x08, manu_id::16, prod_id::16, prod_type::16, version_major,
           version_minor, rest::binary>>,
         extensions
       ) do
    ext = {:product_id, {manu_id, prod_id, prod_type, "#{version_major}.#{version_minor}"}}

    do_parse(rest, [ext | extensions])
  end

  defp do_parse(
         <<@product_type::7, 0::1, 0x04, gen_class, spec_class, icon::16, rest::binary>>,
         extensions
       ) do
    {:ok, icon} = IconType.to_name(icon)
    {:ok, gen_class} = DeviceClasses.generic_device_class_from_byte(gen_class)

    {:ok, spec_class} = DeviceClasses.specific_device_class_from_byte(gen_class, spec_class)

    ext = {:product_type, {gen_class, spec_class, icon}}

    do_parse(rest, [ext | extensions])
  end

  defp do_parse(
         <<@smart_start_inclusion_setting::7, 1::1, 0x01, setting, rest::binary>>,
         extensions
       ) do
    setting =
      case setting do
        0x00 -> :pending
        0x02 -> :passive
        0x03 -> :ignored
      end

    ext = {:smart_start_inclusion_setting, setting}

    do_parse(rest, [ext | extensions])
  end

  defp do_parse(
         <<@uuid16::7, 0::1, len, values::binary-size(len)-unit(8), rest::binary>>,
         extensions
       ) do
    {:ok, uuid} = UUID16.parse(<<@uuid16::7, 0::1, len, values::binary>>)

    ext = {:uuid16, uuid}

    do_parse(rest, [ext | extensions])
  end

  defp do_parse(<<type, len, values::binary-size(len)-unit(8), rest::binary>>, extensions) do
    ext = {:unknown, <<type, len, values::binary>>}

    do_parse(rest, [ext | extensions])
  end

  defp unmask_keys(byte) do
    Enum.reduce(Security.keys(), [], fn key, keys ->
      if byte_has_key?(<<byte>>, key) do
        [key | keys]
      else
        keys
      end
    end)
  end

  defp byte_has_key?(<<_::7, 1::1>>, :s2_unauthenticated), do: true
  defp byte_has_key?(<<_::6, 1::1, _::1>>, :s2_authenticated), do: true
  defp byte_has_key?(<<_::5, 1::1, _::2>>, :s2_access_control), do: true
  defp byte_has_key?(<<_::1, 1::1, _::6>>, :s0), do: true
  defp byte_has_key?(_byte, _key), do: false

  defp set_circuital_bit(byte, cbit) do
    <<byte::7, cbit::1>>
  end

  defp decode_status(status_byte) do
    case status_byte do
      0x00 -> :not_in_network
      0x01 -> :included
      0x02 -> :failing
    end
  end
end
