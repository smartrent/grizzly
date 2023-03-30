defmodule GrizzlyDev.CommandModuleNameMatch do
  @moduledoc """
  Compilation tracer that checks for consistency in command naming.
  """
  use Credo.Check, base_priority: :high, category: :consistency, exit_status: 1

  alias Credo.SourceFile
  alias Credo.IssueMeta
  alias Credo.Code.Module, as: CredoModule

  @explanation [
    check: @moduledoc,
    params: []
  ]

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    ast = SourceFile.ast(source_file)
    issue_meta = IssueMeta.for(source_file, params)

    {_, %{issues: issues}} =
      Macro.prewalk(ast, %{issue_meta: issue_meta, issues: []}, &traverse/2)

    issues
  end

  # defp traverse(_ = ast, acc), do: {ast, acc}

  defp traverse(
         {:defmodule, _, [{:__aliases__, _, module_name}, _]} = ast,
         acc
       ) do
    case module_name do
      [:Grizzly, :ZWave, :Commands, _] ->
        {ast, Map.merge(acc, %{module_name: module_name, aliases: CredoModule.aliases(ast)})}

      _ ->
        {ast, acc}
    end
  end

  defp traverse(
         {:def, _, [{fun, _, _}, _]} = ast,
         acc
       ) do
    {ast, Map.put(acc, :fun_name, fun)}
  end

  defp traverse(
         {:%, _, [{:__aliases__, meta, [:Command]}, {:%{}, _, struct_members}]} = ast,
         %{fun_name: :new, module_name: [:Grizzly, :ZWave, :Commands, module_cmd_name]} = acc
       ) do
    struct_cmd_name = Keyword.fetch!(struct_members, :name)

    if Macro.camelize(Atom.to_string(struct_cmd_name)) != Atom.to_string(module_cmd_name) do
      issue =
        issue_for(acc.issue_meta, Keyword.get(meta, :line), struct_cmd_name, module_cmd_name)

      {ast, %{acc | issues: [issue] ++ acc.issues}}
    else
      {ast, acc}
    end
  end

  defp traverse(ast, acc) do
    {ast, acc}
  end

  defp issue_for(issue_meta, line_no, trigger, module_name) do
    format_issue(issue_meta,
      message: "Command name :#{trigger} does not match module name #{module_name}",
      line_no: line_no,
      trigger: trigger
    )
  end
end
