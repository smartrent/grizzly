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
    {opts, args, _} =
      OptionParser.parse(args, switches: @switches)

    command_name = args |> Enum.at(0) |> maybe_prompt("Command:")
    command_id = args |> Enum.at(1) |> maybe_prompt_for_command_id()
    command_class = args |> Enum.at(2) |> maybe_prompt("Command Class:")

    params =
      args
      |> Enum.drop(3)
      |> Enum.reverse()
      |> Enum.map(&{&1, "any()"})
      |> prompt_for_params(true)
      |> Enum.reverse()

    target_defs = build_target_defs(command_name, opts)

    copy_files(target_defs, command_name, command_id, command_class, params, opts)
  end

  defp maybe_prompt(value, prompt) do
    value = value || String.trim(Mix.shell().prompt(prompt))

    if value == "" or not is_binary(value) do
      maybe_prompt("", prompt)
    else
      value
    end
  end

  defp maybe_prompt_for_command_id(id \\ nil) do
    id = id || String.trim(Mix.shell().prompt("Command ID (hex):"))

    case Regex.run(~r/^0?x?([0-9A-Fa-f]{2})$/, id) do
      [_, id] -> "0x" <> String.upcase(id)
      _ -> maybe_prompt_for_command_id()
    end
  end

  defp print_param_help() do
    Mix.shell().info("")
    Mix.shell().info("Enter one of the following commands to add command parameters:")
    Mix.shell().info("")
    Mix.shell().info(["* ", :bright, "a <name> [<type>]", :reset, " - add a parameter"])
    Mix.shell().info(["* ", :bright, "d <name>", :reset, " - delete a parameter by name"])
    Mix.shell().info(["* ", :bright, "v", :reset, " - show parameter list"])
    Mix.shell().info(["* ", :bright, "x", :reset, " - done entering parameters"])
    Mix.shell().info(["* ", :bright, "?", :reset, " - display this message again"])
  end

  defp print_params(params) do
    params
    |> Enum.reverse()
    |> Enum.each(fn {n, t} ->
      Mix.shell().info(["* ", :green, :bright, ":#{n}", :reset, " :: ", :yellow, "#{t}", :reset])
    end)
  end

  defp prompt_for_params(params, print_help \\ false) do
    if print_help do
      print_param_help()
    end

    Mix.shell().info("")

    cmd =
      Mix.shell().prompt(">")
      |> String.trim()
      |> String.downcase()
      |> String.split(~r/\s+/)

    case cmd do
      ["a", name, type] ->
        type = if(String.ends_with?(type, "()"), do: type, else: type <> "()")
        params = [{name, type} | params]
        prompt_for_params(params)

      ["a", name] ->
        params = [{name, "any()"} | params]
        prompt_for_params(params)

      ["d", name] ->
        params = Enum.reject(params, fn {n, _} -> n == name end)
        prompt_for_params(params)

      ["v"] ->
        print_params(params)
        prompt_for_params(params)

      ["?"] ->
        prompt_for_params(params, true)

      ["x"] ->
        params

      _ ->
        prompt_for_params(params)
    end
  end

  defp copy_files(target_defs, command_name, command_id, command_class, params, opts) do
    command_module = Module.concat(Grizzly.ZWave.Commands, command_name)
    command_name_snakecase = String.to_atom(Macro.underscore(command_name))
    command_class_module = Module.concat(Grizzly.ZWave.CommandClasses, command_class)

    bindings = [
      params: params,
      command_name: command_name_snakecase,
      command_id: command_id,
      command_module: command_module,
      command_module_short: command_name,
      command_class_module: command_class_module,
      command_class_module_short: Module.concat([String.to_atom(command_class)])
    ]

    Enum.each(target_defs, fn target_def ->
      to_out(target_def, bindings, opts)
    end)
  end

  defp to_out({:target, target_file, template_file}, bindings, opts) do
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
    target_template = Path.join(grizzly_path, "/priv/templates/zwave.gen/command.eex")
    test_template = Path.join(grizzly_path, "/priv/templates/zwave.gen/command_test.eex")

    [
      {:target, target, target_template},
      {:target_test, test_target, test_template}
    ]
  end
end
