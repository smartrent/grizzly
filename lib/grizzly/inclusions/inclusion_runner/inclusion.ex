defmodule Grizzly.Inclusions.InclusionRunner.Inclusion do
  @moduledoc false

  # This module is useful for moving an inclusion process through
  # the various states

  alias Grizzly.ZWave.Command
  alias Grizzly.ZWave.Commands.{NodeAdd, NodeRemove, NodeAddKeysSet, NodeAddDSKSet, LearnModeSet}

  @type state ::
          :started
          | :complete
          | :node_adding
          | :node_adding_stop
          | :node_removing_stop
          | :node_removing
          | :keys_requested
          | :keys_granted
          | :dsk_requested
          | :dsk_set
          | :learn_mode
          | :learn_mode_stop

  @type t :: %__MODULE__{
          handler: pid() | module() | {module(), keyword},
          current_command_ref: reference(),
          controller_id: Grizzly.node_id(),
          state: state(),
          dsk_input_length: non_neg_integer() | nil
        }

  defstruct handler: nil,
            current_command_ref: nil,
            controller_id: nil,
            state: :started,
            dsk_input_length: nil

  @spec current_command_ref(t()) :: reference()
  def current_command_ref(inclusion), do: inclusion.current_command_ref

  def update_command_ref(inclusion, new_command_ref),
    do: %__MODULE__{inclusion | current_command_ref: new_command_ref}

  @spec controller_id(t()) :: Grizzly.node_id()
  def controller_id(inclusion), do: inclusion.controller_id

  @doc """
  Handle incoming command from the Z-Wave network

  This commands are:

   - `:node_add_keys_report` - command to tell Grizzly to add the security keys
   - `:node_add_status` - the report about the node add process
   - `:node_remove_status` - the report about the node removal process
   - `:node_add_dsk_report` - the report to tell Grizzly to add the DSK
   - `:learn_mode_set_status` - the report about setting learn mode
  """
  @spec handle_command(t(), Command.t(), keyword()) :: t()
  def handle_command(inclusion, command, opts \\ []) do
    case command.name do
      :node_add_keys_report -> keys_requested(inclusion)
      :node_add_status -> complete(inclusion)
      :node_remove_status -> complete(inclusion)
      :node_add_dsk_report -> dsk_requested(inclusion, opts)
      :learn_mode_set_status -> complete(inclusion)
    end
  end

  @spec complete?(t()) :: boolean()
  def complete?(%__MODULE__{state: :complete}), do: true
  def complete?(%__MODULE__{}), do: false

  @doc """
  Generate the next command based off the desired state of the inclusion

  This will return the next Z-Wave command to run along with the updated
  inclusion to track the current state of the inclusion
  """
  @spec next_command(t(), state(), Grizzly.seq_number(), keyword()) ::
          {Command.t() | nil, t()} | {:error, :dsk_required}
  def next_command(inclusion, desired_state, seq_number, command_params \\ [])

  def next_command(inclusion, :node_adding, seq_number, _command_params) do
    {:ok, command} = NodeAdd.new(seq_number: seq_number)
    {command, node_adding(inclusion)}
  end

  def next_command(inclusion, :node_adding_stop, seq_number, _) do
    {:ok, command} = NodeAdd.new(seq_number: seq_number, mode: :node_add_stop)
    {command, node_adding_stop(inclusion)}
  end

  def next_command(inclusion, :node_removing, seq_number, _) do
    {:ok, command} = NodeRemove.new(seq_number: seq_number)
    {command, node_removing(inclusion)}
  end

  def next_command(inclusion, :node_removing_stop, seq_number, _) do
    {:ok, command} = NodeRemove.new(seq_number: seq_number, mode: :remove_node_stop)
    {command, node_removing_stop(inclusion)}
  end

  def next_command(inclusion, :keys_requested, _seq_number, _) do
    {nil, keys_requested(inclusion)}
  end

  def next_command(inclusion, :keys_granted, seq_number, command_params) do
    {:ok, command} = NodeAddKeysSet.new(command_params ++ [seq_number: seq_number])
    {command, keys_granted(inclusion)}
  end

  def next_command(inclusion, :dsk_set, seq_number, command_params) do
    dsk = Keyword.fetch!(command_params, :dsk)
    input_dsk_length = byte_size_for_int(dsk)

    if input_dsk_length == inclusion.dsk_input_length do
      {:ok, command} =
        NodeAddDSKSet.new(
          seq_number: seq_number,
          accept: true,
          input_dsk_length: input_dsk_length,
          input_dsk: dsk
        )

      {command, dsk_set(inclusion)}
    else
      {:error, :dsk_required}
    end
  end

  def next_command(inclusion, :learn_mode, seq_number, _) do
    {:ok, command} =
      LearnModeSet.new(
        seq_number: seq_number,
        mode: :direct_range_only,
        return_interview_status: :off
      )

    {command, learn_mode(inclusion)}
  end

  def next_command(inclusion, :learn_mode_stop, seq_number, _) do
    {:ok, command} =
      LearnModeSet.new(seq_number: seq_number, mode: :disable, return_interview_status: :off)

    {command, learn_mode_stop(inclusion)}
  end

  def node_adding(%__MODULE__{state: :started} = inclusion) do
    %__MODULE__{inclusion | state: :node_adding}
  end

  def node_adding_stop(%__MODULE__{state: :node_adding} = inclusion) do
    %__MODULE__{inclusion | state: :node_adding_stop}
  end

  def node_removing(%__MODULE__{state: :started} = inclusion) do
    %__MODULE__{inclusion | state: :node_removing}
  end

  def node_removing_stop(%__MODULE__{state: :node_removing} = inclusion) do
    %__MODULE__{inclusion | state: :node_removing_stop}
  end

  def complete(%__MODULE__{state: state} = inclusion)
      when not (state in [:started, :complete]) do
    %__MODULE__{inclusion | state: :complete}
  end

  def keys_requested(%__MODULE__{state: :node_adding} = inclusion) do
    %__MODULE__{inclusion | state: :keys_requested}
  end

  def keys_granted(%__MODULE__{state: :keys_requested} = inclusion) do
    %__MODULE__{inclusion | state: :keys_granted}
  end

  def dsk_requested(%__MODULE__{state: :keys_granted} = inclusion, opts) do
    dsk_input_length = Keyword.fetch!(opts, :dsk_input_length)
    %__MODULE__{inclusion | state: :dsk_requested, dsk_input_length: dsk_input_length}
  end

  def dsk_set(%__MODULE__{state: :dsk_requested} = inclusion) do
    %__MODULE__{inclusion | state: :dsk_set}
  end

  def learn_mode(%__MODULE__{state: :started} = inclusion) do
    %__MODULE__{inclusion | state: :learn_mode}
  end

  def learn_mode_stop(%__MODULE__{state: :learn_mode} = inclusion) do
    %__MODULE__{inclusion | state: :learn_mode_stop}
  end

  # Have not ran into any case for need to check higher than two
  # bytes. If this happens the guards should fail loudly and we can
  # add support quickly
  defp byte_size_for_int(0), do: 0
  defp byte_size_for_int(integer) when integer in 0x00..0xFF, do: 1
  defp byte_size_for_int(integer) when integer in 0x0100..0xFFFF, do: 2
end
