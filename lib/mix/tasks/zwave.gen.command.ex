defmodule Mix.Tasks.Zwave.Gen.Command do
  @moduledoc """
  Generates the scaffolding for a new Z-Wave Command

    mix zwave.gen.command ThermostatModeSet Thermostat mode

  The pattern is

    mix zwave.gen.command CommandModuleName CommandClassModule params....

  Flags:

    * `--no-save` - will print the generated module out to the console
    * `--target-dir <path>` - will generate the new module at the provided path
    * `--no_test` - if set, will not generate a test file
  """

  use Mix.Task

  @shortdoc "Generates the scaffolding for a new Z-Wave Command"

  @switches [no_save: :boolean, target_dir: :string, no_test: :boolean]

  def run(args) do
    {opts, [command_name, command_class | params], _} =
      OptionParser.parse(args, switches: @switches)

    target_defs = build_target_defs(command_name, opts)

    copy_files(target_defs, command_name, command_class, params, opts)
  end

  defp copy_files(target_defs, command_name, command_class, params, opts) do
    command_module = Module.concat(Grizzly.ZWave.Commands, command_name)
    command_name = String.to_atom(Macro.underscore(command_name))
    command_class_module = Module.concat(Grizzly.ZWave.CommandClasses, command_class)

    bindings = [
      params: Enum.map(params, &String.to_atom/1),
      command_name: command_name,
      command_module: command_module,
      command_class_module: command_class_module
    ]

    Enum.each(target_defs, fn target_def ->
      to_out(target_def, bindings, opts)
    end)
  end

  defp to_out({:target, target_file, template_file}, bindings, opts) do
    evaled = EEx.eval_file(template_file, bindings)

    if Keyword.has_key?(opts, :no_save) do
      IO.puts(evaled)
    else
      Mix.Generator.create_file(target_file, evaled)
    end

    :ok
  end

  defp to_out({:target_test, test_file, test_template_file}, bindings, opts) do
    if Keyword.has_key?(opts, :no_test) || Keyword.has_key?(opts, :no_save) do
      :ok
    else
      Mix.Generator.create_file(test_file, EEx.eval_file(test_template_file, bindings))
    end
  end

  defp get_target(file_name, opts) do
    case Keyword.get(opts, :target_dir) do
      nil ->
        Path.join([
          File.cwd!(),
          "lib",
          "grizzly",
          "zwave",
          "commands",
          "#{file_name}.ex"
        ])

      target_dir ->
        Path.join([File.cwd!(), "lib", target_dir, "#{file_name}.ex"])
    end
  end

  defp get_test_target(file_name, opts) do
    case Keyword.get(opts, :target_dir) do
      nil ->
        Path.join([
          File.cwd!(),
          "test",
          "grizzly",
          "zwave",
          "commands",
          "#{file_name}_test.exs"
        ])

      target_dir ->
        Path.join([File.cwd!(), "test", target_dir, "#{file_name}_test.exs"])
    end
  end

  defp build_target_defs(command_name, opts) do
    command_name_str = Macro.underscore(command_name)
    grizzly_path = Application.app_dir(:grizzly)
    target = get_target(command_name_str, opts)
    test_target = get_test_target(command_name_str, opts)
    target_template = Path.join(grizzly_path, "/priv/templates/zwave.gen/command.ex")
    test_template = Path.join(grizzly_path, "/priv/templates/zwave.gen/command_test.exs")

    [
      {:target, target, target_template},
      {:target_test, test_target, test_template}
    ]
  end
end
