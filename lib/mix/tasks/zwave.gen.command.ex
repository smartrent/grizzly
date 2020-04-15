defmodule Mix.Tasks.Zwave.Gen.Command do
  @moduledoc """
  Generates the scaffolding for a new Z-Wave Command

    mix zwave.gen.command ThermostatModeSet Thermostat mode

  The pattern is

    mix zwave.gen.command CommandModuleName CommandClassModule params....

  Flags:

    * `--no-save` - will print the generated module out to the console
    * `--target-dir <path>` - will generate the new module at the provided path
  """

  use Mix.Task

  @shortdoc "Generates the scaffolding for a new Z-Wave Command"

  @switches [no_save: :boolean, target_dir: :string]

  def run(args) do
    {opts, [command_name, command_class | params], _} =
      OptionParser.parse(args, switches: @switches)

    command_name_str_snake_case = Macro.underscore(command_name)

    target_path = Path.join(get_target(opts), "#{command_name_str_snake_case}.ex")

    copy_files(target_path, command_name, command_class, params, opts)
  end

  defp copy_files(target_path, command_name, command_class, params, opts) do
    template_file =
      Path.join(Application.app_dir(:grizzly), "/priv/templates/zwave.gen/command.ex")

    command_module = Module.concat(Grizzly.ZWave.Commands, command_name)
    command_name = String.to_atom(Macro.underscore(command_name))
    command_class_module = Module.concat(Grizzly.ZWave.CommandClasses, command_class)

    bindings = [
      params: Enum.map(params, &String.to_atom/1),
      command_name: command_name,
      command_module: command_module,
      command_class_module: command_class_module
    ]

    to_out(target_path, template_file, bindings, opts)
  end

  defp to_out(target_path, template_file, bindings, opts) do
    evaled = EEx.eval_file(template_file, bindings)

    if Keyword.has_key?(opts, :no_save) do
      IO.puts(evaled)
    else
      Mix.Generator.create_file(target_path, EEx.eval_file(template_file, bindings))
    end
  end

  def get_target(opts) do
    case Keyword.get(opts, :target_dir) do
      nil ->
        Path.join([
          File.cwd!(),
          "lib",
          "grizzly",
          "zwave",
          "commands"
        ])

      target_dir ->
        target_dir
    end
  end
end
