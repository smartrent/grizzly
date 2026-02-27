defmodule Grizzly.ZWave.Macros do
  @moduledoc """
  DSL macros for declaratively defining Z-Wave command specifications.

  These macros provide a clean, readable syntax for specifying command parameters,
  eliminating boilerplate code for straightforward command encoding/decoding.

  ## Core Macros

  ### `command_class/3`

  Defines a command class and its associated commands:

      command_class :switch_binary, 0x25 do
        command :switch_binary_set, 0x01, Cmds.Generic, params: [...]
        command :switch_binary_get, 0x02, Cmds.Generic, params: []
        command :switch_binary_report, 0x03, Cmds.Generic, params: [...]
      end

  ### `command/4`

  Defines a single Z-Wave command with its byte value, module, and parameters:

      command :clock_set, 0x04, Cmds.Generic,
        params: [
          enum(:weekday, clock_weekdays, size: 3),
          param(:hour, :uint, size: 5)
        ]

  ## Parameter Macros

  ### `param/3` - Basic Parameters

  Define typed parameters with size in bits:

      param(:value, :uint, size: 8)           # Single byte unsigned integer
      param(:temperature, :int, size: 16)     # Two-byte signed integer
      param(:name, :binary, size: :variable)  # Variable-length binary data

  **Supported Types:**
  - `:uint` - Unsigned integer
  - `:int` - Signed integer
  - `:binary` - Raw binary data
  - `:boolean` - True/false (encoded as 0/1 or 0xFF/0x00)

  ### `enum/3` - Enumerated Values

  Map symbolic names to numeric values:

      enum(:mode, ZWEnum.new(off: 0, heat: 1, cool: 2), size: 8)

  Usage: `Commands.create(:thermostat_mode_set, mode: :heat)`

  ### `list/2` - Variable-Length Lists

  Define lists with item type and optional length encoding:

      list(:nodes, item_type: :uint, item_size: 8, length: :remaining)
      list(:data, item_type: :binary, item_size: 16, prefix_size: 8)

  **Options:**
  - `item_type:` - Type of each item (`:uint`, `:binary`, etc.)
  - `item_size:` - Size of each item in bits
  - `length:` - `:remaining` (rest of binary) or count of items
  - `prefix_size:` - Bits for length prefix (default: 8)

  ### `bitmask/3` - Bit Flags

  Define multiple boolean flags packed into a single byte:

      bitmask(:capabilities,
        ZWEnum.new(temperature: 0x01, humidity: 0x02, pressure: 0x04),
        size: 8)

  Usage: `Commands.create(:report, capabilities: [:temperature, :humidity])`

  ### `marker/1` - Separator Bytes

  Fixed-value bytes used as separators or padding:

      marker(value: 0x00, size: 8)  # Single zero byte separator

  Useful for protocols that separate list sections with specific bytes.

  ### `reserved/1` - Reserved Bits

  Padding or reserved bits in the protocol:

      reserved(size: 5)  # 5 bits of padding

  ## Advanced Features

  ### Conditional Fields (`:when`)

  Fields can be present or absent based on other parameter values:

      param(:extended_data, :binary, size: 16,
        when: {:field_not_empty, :type})

  **Condition Types:**
  - `{:field_equals, :field_name, value}` - Field must equal value
  - `{:field_not_equals, :field_name, value}` - Field must not equal value
  - `{:field_empty, :field_name}` - Field is `nil`, `[]`, or `""`
  - `{:field_not_empty, :field_name}` - Field has a value
  - `{Module, :function}` - Custom function receives params, returns boolean

  ### Computed Values (`:compute`)

  Values can be computed from other parameters:

      param(:checksum, :uint, size: 8,
        compute: {ChecksumHelper, :calculate})

  The compute function receives all parameters and returns the computed value.

  ### Variable-Length Fields

  Fields can reference other parameters for their length:

      param(:length, :uint, size: 8)
      param(:data, :binary, size: {:variable, :length})

  Or consume all remaining bytes:

      param(:trailing_data, :binary, size: :variable)  # Must be last

  ## Complete Example

  Here's a realistic command definition showing multiple features:

      command :user_code_set, 0x01, Cmds.Generic,
        params: [
          param(:user_identifier, :uint, size: 8),
          enum(:user_id_status, user_id_statuses, size: 8),
          param(:user_code, :binary, size: :variable,
            when: {:field_equals, :user_id_status, :enabled},
            compute: {UserCodeHelpers, :encode_code})
        ]

  ## Migration from Custom to Declarative

  When migrating a custom command implementation to use these macros:

  1. Identify the binary layout from the custom encoder
  2. Map each field to the appropriate parameter macro
  3. Handle conditional logic with `:when` conditions
  4. Test that encoding/decoding produces identical results
  5. Remove the custom module once validated

  See `docs/refactoring_examples.md` for detailed migration examples.
  """

  defmacro __using__(_opts) do
    quote do
      import Grizzly.ZWave.Macros

      @before_compile Grizzly.ZWave.Macros
      Module.register_attribute(__MODULE__, :command_spec_def_locations, accumulate: true)
      Module.register_attribute(__MODULE__, :command_specs, accumulate: true)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @final_commands Map.new(@command_specs, fn cmd -> {cmd.name, cmd} end)
      def builtin_commands() do
        @final_commands
      end
    end
  end

  defmacro command_class(name, _byte, do: block) do
    quote do
      var!(cc_name, Grizzly.ZWave.Macros) = unquote(name)
      unquote(block)
    end
  end

  defmacro command(name, byte, mod \\ [], opts \\ [])

  defmacro command(name, byte, mod, opts) when is_list(mod) do
    opts = Keyword.merge(mod, opts)

    cmd_mod_name = name |> Atom.to_string() |> Macro.camelize() |> String.to_atom()

    # Have to define this as an AST node. If we build it with with Module.concat,
    # the compiler doesn't recognize that it needs to be a compile-time dependency.
    mod = {:__aliases__, [alias: false], [:Grizzly, :ZWave, :Commands, cmd_mod_name]}

    do_command(__CALLER__, name, byte, mod, opts)
  end

  defmacro command(name, byte, mod, opts) do
    do_command(__CALLER__, name, byte, mod, opts)
  end

  defmacro param(name, type, opts \\ []) do
    quote bind_quoted: [
            name: name,
            type: type,
            opts: opts
          ] do
      {name,
       struct!(
         Grizzly.ZWave.ParamSpec,
         Keyword.merge(opts,
           name: name,
           type: type
         )
       )}
    end
  end

  defmacro reserved(opts) do
    quote bind_quoted: [opts: opts] do
      {:reserved,
       struct!(
         Grizzly.ZWave.ParamSpec,
         Keyword.merge(opts,
           name: :reserved,
           type: :reserved
         )
       )}
    end
  end

  defmacro enum(name, values, opts) do
    quote bind_quoted: [
            name: name,
            values: values,
            opts: opts
          ] do
      {name,
       struct!(
         Grizzly.ZWave.ParamSpec,
         Keyword.merge(opts,
           name: name,
           type: :enum,
           opts: Keyword.merge(opts[:opts] || [], values: values)
         )
       )}
    end
  end

  defmacro bitmask(name, values, opts) do
    quote bind_quoted: [
            name: name,
            values: values,
            opts: opts
          ] do
      {name,
       struct!(
         Grizzly.ZWave.ParamSpec,
         Keyword.merge(opts,
           name: name,
           type: :bitmask,
           opts: Keyword.merge(opts[:opts] || [], values: values)
         )
       )}
    end
  end

  defmacro list(name, opts) do
    quote bind_quoted: [
            name: name,
            opts: opts
          ] do
      # Extract opts that go into the ParamSpec.opts
      item_type = Keyword.fetch!(opts, :item_type)
      item_size = Keyword.get(opts, :item_size, 8)
      length = Keyword.get(opts, :length, :remaining)
      item_opts = Keyword.get(opts, :item_opts, [])
      prefix_size = Keyword.get(opts, :prefix_size, 8)

      # Extract opts that go into the ParamSpec itself
      param_opts =
        opts
        |> Keyword.drop([:item_type, :item_size, :length, :item_opts, :prefix_size])

      {name,
       struct!(
         Grizzly.ZWave.ParamSpec,
         Keyword.merge(param_opts,
           name: name,
           type: :list,
           size: :variable,
           opts: [
             item_type: item_type,
             item_size: item_size,
             length: length,
             item_opts: item_opts,
             prefix_size: prefix_size
           ]
         )
       )}
    end
  end

  defmacro marker(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      marker_value = Keyword.get(opts, :value, 0x00)
      size = Keyword.get(opts, :size, 8)
      name = Keyword.get(opts, :name, :marker)
      when_cond = Keyword.get(opts, :when)

      param_opts =
        opts
        |> Keyword.drop([:value, :size, :name, :when])

      {name,
       struct!(
         Grizzly.ZWave.ParamSpec,
         Keyword.merge(param_opts,
           name: name,
           type: :marker,
           size: size,
           required: false,
           when: when_cond,
           opts: [value: marker_value]
         )
       )}
    end
  end

  defp do_command(caller, name, byte, mod, opts) do
    quote bind_quoted: [
            name: name,
            byte: byte,
            mod: mod,
            opts: opts,
            file: caller.file,
            line: caller.line
          ] do
      @command_spec_def_locations {name, {file, line}}
      @command_specs Grizzly.ZWave.CommandSpec.new(
                       [
                         command_class: var!(cc_name, Grizzly.ZWave.Macros),
                         name: name,
                         command_byte: byte,
                         module: mod
                       ] ++ opts
                     )
    end
  end
end
