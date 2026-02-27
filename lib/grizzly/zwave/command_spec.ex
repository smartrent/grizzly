defmodule Grizzly.ZWave.CommandSpec do
  @moduledoc """
  Specification for a Z-Wave command defining its structure and behavior.

  A `CommandSpec` describes everything needed to work with a Z-Wave command:
  - Identity (name, command class, command byte)
  - How to encode parameters into binary format
  - How to decode binary data back into parameters
  - Default parameter values
  - Report matching for request/response correlation
  - Handler configuration for asynchronous operations

  ## Role in the System

  CommandSpecs serve as the bridge between high-level command usage and low-level
  binary Z-Wave protocol. They are typically created automatically by the macro system
  when commands are defined in `Grizzly.ZWave.Commands`.

  ## Two Approaches to Command Specifications

  ### 1. Declarative (Generic) Commands

  Commands defined with parameter specifications use `Grizzly.ZWave.Commands.Generic`
  for encoding/decoding:

      command :switch_binary_set, 0x01, Cmds.Generic,
        params: [
          param(:value, :uint, size: 8),
          param(:duration, :uint, size: 8, default: 0)
        ]

  The resulting CommandSpec has:
  - `encode_fun: {Generic, :encode_params}`
  - `decode_fun: {Generic, :decode_params}`
  - `params:` List of `{name, ParamSpec}` tuples

  ### 2. Custom Implementation Commands

  Commands with complex requirements specify their own module:

      command :alarm_report, 0x05  # Uses Grizzly.ZWave.Commands.AlarmReport

  The resulting CommandSpec has:
  - `encode_fun: {AlarmReport, :encode_params}`
  - `decode_fun: {AlarmReport, :decode_params}`
  - Module must implement `Grizzly.ZWave.Command` behavior

  ## Examples

      # Create a command spec programmatically (usually done by macros)
      spec = CommandSpec.new(
        name: :switch_binary_set,
        command_class: :switch_binary,
        command_byte: 0x01,
        module: Cmds.Generic,
        params: [
          {:value, %ParamSpec{name: :value, type: :uint, size: 8}}
        ]
      )

      # Use it to create and encode a command
      {:ok, cmd} = CommandSpec.create_command(spec, value: 255)
      binary = apply(spec.encode_fun, [spec, cmd])

      # Decode a binary using the spec
      {:ok, params} = apply(spec.decode_fun, [spec, <<0xFF>>])
      #=> {:ok, [value: 255]}

  ## Report Matching

  Z-Wave commands often follow a request/response pattern where a "get" command
  expects a corresponding "report" command as a response. The CommandSpec supports
  two levels of report matching:

  ### 1. Command Name Matching (`:report`)

  The simplest approach matches by command name only:

      command :thermostat_mode_get, 0x02, Cmds.Generic,
        report: :thermostat_mode_report,
        params: []

  When a `:thermostat_mode_get` is sent, the system waits for any
  `:thermostat_mode_report` response.

  ### 2. Parameter-Based Matching (`:report_matcher_fun`)

  For commands where multiple requests may be in flight, or where the report must
  match specific parameter values from the request, use a matcher function:

      command :user_code_get, 0x02, Cmds.Generic,
        report: :user_code_report,
        report_matcher_fun: {UserCode, :report_matches_get?},
        params: [param(:user_identifier, :uint, size: 8)]

      # In the UserCode module:
      def report_matches_get?(get_cmd, report_cmd) do
        Command.param!(get_cmd, :user_identifier) ==
          Command.param!(report_cmd, :user_identifier)
      end

  This ensures the response matches not just the command type, but also has the
  same `:user_identifier` value as the request. This is critical when multiple
  user code requests are outstanding simultaneously.

  **Matcher Function Signature:**
  - Takes two arguments: the original get/request command and the received report
  - Returns `true` if the report matches the request, `false` otherwise
  - Can compare any parameter values between the two commands

  ## Validation

  CommandSpecs can include validation functions to ensure parameter correctness:

      command :user_code_set, 0x01, Cmds.UserCodeSet,
        validate_fun: {UserCodeSet, :validate_params}

  See `validate_params/2` for details on implementing validation.
  """

  alias Grizzly.Requests.Handlers.AckResponse
  alias Grizzly.Requests.Handlers.WaitReport
  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.CommandClasses
  alias Grizzly.ZWave.ParamSpec

  @type report_matcher :: (get :: Command.t(), report :: Command.t() -> boolean())

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
        type: {:custom, __MODULE__, :__validate_fun__, [2]},
        required: true,
        doc: """
        A function or `{module, function}` tuple used to encode the command's
        parameters into a binary. Only 1-arity functions are currently supported.
        """
      ],
      decode_fun: [
        type: {:custom, __MODULE__, :__validate_fun__, [2]},
        required: true,
        doc: """
        A function or `{module, function}` tuple used to decode the command's
        parameters from binary to a keyword list (the reverse of the `encode_fun`).

        If the function is of arity 1, the first argument will be the binary to
        decode. If arity 2, the command spec will be inserted as the first argument.
        """
      ],
      report_matcher_fun: [
        type: {:or, [{:custom, __MODULE__, :__validate_fun__, [2]}, nil]},
        required: false,
        doc: """
        A 2-arity function or `{module, function}` tuple used to match a
        report command to a get/request command based on parameter values.

        The first argument is the original get/request command, and the second
        argument is the received report command. The function should return `true`
        if the report matches the request, `false` otherwise.

        This is essential when:
        - Multiple requests of the same type may be outstanding simultaneously
        - The response must match specific parameter values from the request
        - Example: user_code_get must match user_code_report with same user_identifier

        If not specified, reports are matched by command name only (via `:report` field).
        """
      ],
      report: [
        type: :atom,
        required: false,
        doc: """
        The name of the report command associated with this get/request command, if any.

        For get commands, this will default to the command name with the trailing
        `_get` replaced with `_report`. To override this behavior, explicitly
        set this field to nil.

        This specifies which report command type to wait for. For additional
        parameter-based matching (e.g., matching specific field values), combine
        with `:report_matcher_fun`.

        Examples:
        - `:battery_get` → automatically expects `:battery_report`
        - `:user_code_get` → expects `:user_code_report` (name match) +
          matcher function (parameter match)

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
      validate_fun: [
        type: {:or, [{:custom, __MODULE__, :__validate_fun__, [2]}, nil]},
        required: false,
        doc: """
        A `{module, function}` tuple indicating a function that validates
        the command parameters. The function should return `{:ok, params}` if the
        parameters are valid or have been updated, or `{:error, reason}` if the
        parameters are invalid.
        """
      ],
      params: [
        type: {:custom, __MODULE__, :validate_param_list, []},
        keys: [*: [type: {:struct, ParamSpec}]],
        default: []
      ],
      default_params: [
        type: :keyword_list,
        default: [],
        doc: """
        A keyword list of default parameters for the command. These parameters
        will be merged with any parameters passed to `create_command/2` before
        validation.
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
          encode_fun: {module(), atom()},
          decode_fun: {module(), atom()},
          validate_fun:
            {module(), atom()} | (keyword() -> {:ok, keyword()} | {:error, any()}) | nil,
          report_matcher_fun: {module(), atom()} | nil,
          report: atom() | nil,
          handler: {module(), keyword()},
          supports_supervision?: boolean(),
          params: list({atom(), ParamSpec.t()}),
          default_params: keyword()
        }

  defstruct name: nil,
            command_class: nil,
            command_byte: nil,
            module: nil,
            encode_fun: nil,
            decode_fun: nil,
            validate_fun: nil,
            report_matcher_fun: nil,
            report: nil,
            handler: {AckResponse, []},
            supports_supervision?: false,
            params: [],
            default_params: []

  @doc """
  Create a new command spec.
  """
  @doc group: "Command Specs"
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

  @doc """
  Create a new command spec.
  """
  @doc group: "Command Specs"
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

    # If params is specified, default values in the param specs will override
    # anything in default_params, which will someday be removed.
    params = Keyword.get(fields, :params, [])
    default_params = Keyword.get(fields, :default_params, [])

    defaults_from_param_specs =
      for {name, %ParamSpec{default: default}} <- params, default != nil, into: [] do
        {name, default}
      end

    default_params = Keyword.merge(default_params, defaults_from_param_specs)

    fields =
      Keyword.merge(fields, handler: handler, report: report, default_params: default_params)

    fields =
      if is_nil(module) do
        fields
      else
        [
          module: module,
          encode_fun: maybe_fun_from_module(module, :encode_params, 2),
          decode_fun: maybe_fun_from_module(module, :decode_params, 2),
          validate_fun: maybe_fun_from_module(module, :validate_params, 2),
          report_matcher_fun: maybe_fun_from_module(module, :report_matches_get?, 2)
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

  @doc """
  Validate a command spec.
  """
  @doc group: "Command Specs"
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
  def __validate_fun__({mod, fun} = v, arity) when is_atom(mod) and is_atom(fun) do
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

  def __validate_fun__(v, _arity), do: {:error, inspect(v)}

  @doc """
  Get the handler and options for a command.
  """
  @doc group: "Command Specs"
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

  defp maybe_fun_from_module(module, fun, arity) do
    _ = Code.ensure_compiled(module)

    if function_exported?(module, fun, arity) do
      {module, fun}
    else
      nil
    end
  end

  @doc """
  Validates a list of parameter specs.

  ## Examples

      iex> params = [
      ...>   param1: %Grizzly.ZWave.ParamSpec{name: :param1, type: :uint, size: 8},
      ...>   param2: %Grizzly.ZWave.ParamSpec{name: :param2, type: :int, size: 16}
      ...> ]
      iex> Grizzly.ZWave.CommandSpec.validate_param_list(params)
      {:ok, params}

      iex> params = [
      ...>   param1: %Grizzly.ZWave.ParamSpec{name: :param1, type: :uint, size: 7},
      ...>   param2: %Grizzly.ZWave.ParamSpec{name: :param2, type: :int, size: 8}
      ...> ]
      iex> Grizzly.ZWave.CommandSpec.validate_param_list(params)
      {:error, "Total size of all non-variable parameters must be a multiple of 8 bits"}

      iex> params = [
      ...>   param1: %Grizzly.ZWave.ParamSpec{name: :param1, type: :uint, size: :variable},
      ...>   param2: %Grizzly.ZWave.ParamSpec{name: :param2, type: :int, size: 16}
      ...> ]
      iex> Grizzly.ZWave.CommandSpec.validate_param_list(params)
      {:error, "Variable-length parameter without length specifier must be last"}
  """
  @doc group: "Command Specs"
  @spec validate_param_list(list({atom(), ParamSpec.t()})) ::
          {:ok, list({atom(), ParamSpec.t()})} | {:error, String.t()}
  def validate_param_list(params) do
    with :ok <- validate_param_list_size(params),
         :ok <- variable_param_without_length_must_be_last(params) do
      {:ok, params}
    end
  end

  defp validate_param_list_size(params, bits \\ 0)

  defp validate_param_list_size([], bits) when rem(bits, 8) == 0, do: :ok

  # skip when size is :variable or {:variable, _}
  defp validate_param_list_size([{_, %{size: size}} | params], bits)
       when size == :variable or (is_tuple(size) and elem(size, 0) == :variable),
       do: validate_param_list_size(params, bits)

  defp validate_param_list_size([{_, %{type: :binary, size: size}} | params], bits)
       when is_integer(size),
       do: validate_param_list_size(params, bits + size * 8)

  defp validate_param_list_size([{_, %{size: size}} | params], bits)
       when is_integer(size),
       do: validate_param_list_size(params, bits + size)

  defp validate_param_list_size([], _bits) do
    {:error, "Total size of all non-variable parameters must be a multiple of 8 bits"}
  end

  defp variable_param_without_length_must_be_last([{_name, %{size: :variable}} | rest])
       when rest != [] do
    {:error, "Variable-length parameter without length specifier must be last"}
  end

  defp variable_param_without_length_must_be_last([_ | rest]),
    do: variable_param_without_length_must_be_last(rest)

  defp variable_param_without_length_must_be_last([]), do: :ok

  @doc """
  Create a command struct from the command spec and parameters.
  """
  @doc group: "Commands"
  def create_command(%__MODULE__{} = spec, params) do
    params = Keyword.merge(spec.default_params, params)

    with {:ok, params} <- validate_params(spec, params) do
      cmd = %Grizzly.ZWave.Command{
        name: spec.name,
        command_class: spec.command_class,
        command_byte: spec.command_byte,
        params: params
      }

      {:ok, cmd}
    end
  end

  @doc """
  Validate a command's parameters according to the command spec.
  """
  @doc group: "Commands"
  def validate_params(%__MODULE__{validate_fun: nil} = _spec, params) do
    {:ok, params}
  end

  def validate_params(%__MODULE__{validate_fun: {mod, fun}} = spec, params) do
    apply(mod, fun, [spec, params])
  end

  def validate_params(%__MODULE__{validate_fun: fun} = spec, params)
      when is_function(fun, 2) do
    fun.(spec, params)
  end
end
