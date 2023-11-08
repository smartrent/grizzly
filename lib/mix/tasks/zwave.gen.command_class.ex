defmodule Mix.Tasks.Zwave.Gen.CommandClass do
  @moduledoc """
  Generates the scaffolding for a new Z-Wave Command

    mix zwave.gen.command_class ThermostatMode 40

  The pattern is

    mix zwave.gen.command_class CommandClassModule CommandClassID

  Flags:

    * `--no-save` - will print the generated module out to the console
    * `--target-dir <path>` - will generate the new module at the provided path
  """

  use Mix.Task

  @shortdoc "Generates the scaffolding for a new Z-Wave Command Class"

  @switches [no_save: :boolean, target_dir: :string]

  def run(args) do
    {opts, args, _} = OptionParser.parse(args, switches: @switches)

    command_class = args |> Enum.at(0) |> maybe_prompt_for_command_class_name()
    cc_id = args |> Enum.at(1) |> maybe_prompt_for_command_class_id()

    command_class_name_str_snake_case = Macro.underscore(command_class)

    target_path = Path.join(get_target(opts), "#{command_class_name_str_snake_case}.ex")

    copy_files(target_path, command_class, cc_id, opts)
  end

  defp maybe_prompt_for_command_class_name(name \\ nil) do
    name = name || String.trim(Mix.shell().prompt("Command Class:"))

    if name == "" do
      maybe_prompt_for_command_class_name()
    else
      name
    end
  end

  defp maybe_prompt_for_command_class_id(id \\ nil) do
    id = id || String.trim(Mix.shell().prompt("Command Class ID (hex):"))

    case Regex.run(~r/^0?x?([0-9A-Fa-f]{2})$/, id) do
      [_, id] -> "0x" <> String.upcase(id)
      _ -> maybe_prompt_for_command_class_id()
    end
  end

  defp copy_files(target_path, command_class, cc_id, opts) do
    template_file =
      Path.join(Application.app_dir(:grizzly), "/priv/templates/zwave.gen/command_class.eex")

    command_class_module = Module.concat(Grizzly.ZWave.CommandClasses, command_class)
    command_class_name = String.to_atom(Macro.underscore(command_class))

    bindings = [
      command_class_name: command_class_name,
      command_class_module: command_class_module,
      command_class: command_class,
      command_class_id: cc_id
    ]

    to_out(target_path, template_file, bindings, opts)
  end

  defp to_out(target_path, template_file, bindings, opts) do
    evaled = EEx.eval_file(template_file, bindings, trim: true)

    evaled =
      try do
        Code.format_string!(evaled)
      rescue
        _ -> evaled
      end

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
          "command_classes"
        ])

      target_dir ->
        target_dir
    end
  end
end
