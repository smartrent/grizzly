defmodule Grizzly.ZWave.CommandSpec do
  @moduledoc """
  Data structure describing a Z-Wave command, including how to create, encode,
  and decode it.
  """

  alias Grizzly.Requests.Handlers.AckResponse
  alias Grizzly.Requests.Handlers.WaitReport
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses

  @type report_matcher :: (get :: Command.t(), report :: Command.t() -> boolean())

  defmodule Param do
    @moduledoc """
    Data structure describing a parameter for a Z-Wave command.
    """

    @type type :: :integer | :atom | :boolean | :binary | :any

    @type t :: %__MODULE__{
            name: atom(),
            type: type(),
            size: non_neg_integer() | :variable,
            default: any(),
            required: boolean()
          }

    defstruct name: nil,
              type: nil,
              size: 8,
              default: nil,
              required: false
  end

  schema =
    NimbleOptions.new!(
      name: [
        type: :atom,
        required: true,
        doc: """
        The command's name as an atom (should be globally unique).
        """
      ],
      command_class: [
        type: {:custom, __MODULE__, :validate_command_class, []},
        required: true,
        type_spec: quote(do: atom()),
        type_doc: "`t:Grizzly.ZWave.CommandClasses.command_class/0`",
        doc: """
        The command class this command belongs to.
        """
      ],
      module: [
        type: :atom,
        type_spec: quote(do: module()),
        doc: """
        The module implementing this command's encoding and decoding functions.
        """,
        required: true
        # deprecated: "Use `encode_fun` and `decode_fun` instead."
      ],
      command_byte: [
        type: {:in, 0..255},
        required: true,
        doc: """
        The command identifier.
        """
      ],
      encode_fun: [
        type: {:custom, __MODULE__, :validate_fun, [1]},
        required: true,
        doc: """
        A function or `{module, function}` tuple used to encode the command's
        parameters into a binary. Only 1-arity functions are currently supported.
        """
      ],
      decode_fun: [
        type:
          {:or,
           [
             {:custom, __MODULE__, :validate_fun, [1]},
             {:custom, __MODULE__, :validate_fun, [2]}
           ]},
        required: true,
        doc: """
        A function or `{module, function}` tuple used to decode the command's
        parameters from binary to a keyword list (the reverse of the `encode_fun`).

        If the function is of arity 1, the first argument will be the binary to
        decode. If arity 2, the command spec will be inserted as the first argument.
        """
      ],
      report_matcher_fun: [
        type: {:or, [{:tuple, [:atom, :atom]}, nil]},
        required: false,
        doc: """
        A 2-arity function or `{module, function}` tuple used to match a
        report command to a get command. The first argument will be the get
        command and the second argument will be the report command to match.
        The function should return `true` if the report matches the get.
        """
      ],
      report: [
        type: :atom,
        required: false,
        doc: """
        The name of the report command associated with this command, if any.
        For get commands, this will default to the command name with the trailing
        `_get` replaced with `_report`. To override this behavior, explicitly
        set this field to nil.

        A special value of `:any` may be used to indicate that any report command
        can satisfy this particular get command. Otherwise, this should be
        the name of a registered report command.
        """
      ],
      handler: [
        type: {:tuple, [:atom, :keyword_list]},
        required: false,
        doc: """
        A `{module, options}` tuple indicating the request handler
        that should be used to handle completion of this command when sent
        via a `Grizzly.Request`. Normally, this will default to `{AckResponse, []}`.
        However, if the `:report` option is specified but `:handler` is not,
        the default becomes `{WaitReport, complete_report: report}`.
        """
      ],
      supports_supervision?: [
        type: :boolean,
        default: true,
        doc: """
        Whether this command supports Z-Wave Supervision. Defaults to `false`
        for commands whose names end with `_get`. Defaults to `true` for commands
        whose names end with `_set` or `_report`. Defaults to `false` for commands
        named `network_management_*`, as most of these are only supported by
        Z/IP Gateway.
        """
      ],
      default_params: [
        type: :keyword_list,
        default: [],
        doc: """
        A keyword list of default parameters for this command.
        """
      ]
    )

  @schema schema

  @typedoc "#{NimbleOptions.docs(schema)}"
  @type t :: %__MODULE__{
          name: atom(),
          command_class: atom(),
          command_byte: byte(),
          module: module(),
          encode_fun: (Command.t() -> binary()) | {module(), atom()},
          decode_fun: (binary() -> {:ok, keyword()} | {:error, any()}) | {module(), atom()},
          report_matcher_fun: report_matcher() | nil,
          report: atom() | nil,
          handler: {module(), keyword()},
          supports_supervision?: boolean(),
          default_params: keyword()
        }

  defstruct name: nil,
            command_class: nil,
            command_byte: nil,
            module: nil,
            encode_fun: nil,
            decode_fun: nil,
            report_matcher_fun: nil,
            report: nil,
            handler: {AckResponse, []},
            supports_supervision?: false,
            default_params: []

  def create_command(%__MODULE__{} = spec, params) do
    cmd = %Grizzly.ZWave.Command{
      name: spec.name,
      command_class: spec.command_class,
      command_byte: spec.command_byte,
      params: Keyword.merge(spec.default_params, params),
      impl: spec.module
    }

    {:ok, cmd}
  end

  def new(command_class, name, byte, mod, opts) when is_list(opts) do
    new(
      Keyword.merge(opts,
        name: name,
        command_class: command_class,
        command_byte: byte,
        module: mod
      )
    )
  end

  def new(fields) do
    {module, fields} = Keyword.pop(fields, :module)
    handler = Keyword.get(fields, :handler)
    report = Keyword.get_lazy(fields, :report, fn -> default_report(fields[:name]) end)

    name = Keyword.get(fields, :name)

    module =
      cond do
        # if it doesn't look like a module name, return nil
        is_nil(module) or not is_atom(module) -> nil
        # if it's a loaded module, don't rename it
        Code.ensure_loaded?(module) -> module
        # if it's a top-level module name, prepend Grizzly.ZWave.Commands
        match?([_], Module.split(module)) -> Module.concat([Grizzly.ZWave.Commands, module])
        # otherwise, assume it's already fully-qualified
        true -> module
      end

    handler =
      cond do
        handler != nil -> handler
        report != nil -> {WaitReport, complete_report: report}
        true -> {AckResponse, []}
      end

    fields = Keyword.merge(fields, handler: handler, report: report)

    fields =
      if is_nil(module) do
        fields
      else
        [
          module: module,
          encode_fun: {module, :encode_params},
          decode_fun: {module, :decode_params}
        ] ++ fields
      end

    fields =
      Keyword.put_new(
        fields,
        :supports_supervision?,
        default_supports_supervision?(fields[:command_class], name)
      )

    struct!(__MODULE__, fields)
  end

  def validate(%__MODULE__{} = spec) do
    spec
    |> Map.from_struct()
    |> NimbleOptions.validate(@schema)
  end

  @doc false
  def validate_command_class(value) do
    if CommandClasses.valid?(value) do
      {:ok, value}
    else
      {:error, "#{inspect(value)} is not a valid command class"}
    end
  end

  @doc false
  def validate_fun({mod, fun} = v, arity) when is_atom(mod) and is_atom(fun) do
    cond do
      Code.ensure_loaded?(mod) == false ->
        {:error, "module #{inspect(mod)} is not loaded"}

      not function_exported?(mod, fun, arity) ->
        {:error,
         "function #{inspect(mod)}.#{Atom.to_string(fun)}/#{arity} is undefined or private"}

      true ->
        {:ok, v}
    end
  end

  def validate_fun(v, _arity), do: {:error, inspect(v)}

  def handler_spec(%__MODULE__{} = spec) do
    {module, opts} = spec.handler

    if spec.report != nil and not Keyword.has_key?(opts, :complete_report) do
      {module, Keyword.put(opts, :complete_report, spec.report)}
    else
      {module, opts}
    end
  end

  defp default_report(name) do
    name_str = Atom.to_string(name)

    if String.ends_with?(name_str, "_get") do
      name_str
      |> String.replace_suffix("_get", "_report")
      |> String.to_atom()
    else
      nil
    end
  end

  defp default_supports_supervision?(command_class, name) do
    cc = Atom.to_string(command_class)
    c = Atom.to_string(name)

    cond do
      String.starts_with?(cc, "network_management_") -> false
      String.ends_with?(c, "_set") -> true
      String.ends_with?(c, "_report") -> true
      String.ends_with?(c, "_get") -> false
      true -> false
    end
  end
end
