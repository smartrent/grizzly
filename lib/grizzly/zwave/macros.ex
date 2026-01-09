defmodule Grizzly.ZWave.Macros do
  @moduledoc false

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

  defmacro command_class(name, do: block) do
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

  defmacro param(name, type, size, opts \\ []) do
    quote bind_quoted: [
            name: name,
            type: type,
            size: size,
            opts: opts
          ] do
      {name,
       struct!(
         Grizzly.ZWave.CommandSpec.Param,
         Keyword.merge(opts,
           name: name,
           type: type,
           size: size
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
