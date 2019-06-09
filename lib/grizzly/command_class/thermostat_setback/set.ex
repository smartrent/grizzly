defmodule Grizzly.CommandClass.ThermostatSetback.Set do
  @moduledoc """
  Command module to work with the ThermostatSetback command class SET command

  Command Options:

    * `:value` - What the value of the set-point should be
    * `:type` - The setback type being targeted: `:no_override`, `:temporary_override` or `:permanent_override`
    * `:state` - `:frost_protection`, `:energy_saving_mode`  or an integer between -128 and 120 (tenth of degrees)
    * `:seq_number` - The sequence number of the Z/IP Packet
    * `:retries` - The number of times to try to send the command (default 2)
  """
  @behaviour Grizzly.Command

  alias Grizzly.Packet
  alias Grizzly.CommandClass.ThermostatSetback

  @type t :: %__MODULE__{
          type: ThermostatSetback.setback_type(),
          state: ThermostatSetback.setback_state(),
          seq_number: Grizzly.seq_number(),
          retries: non_neg_integer()
        }

  @type opt ::
          {:type, ThermostatSetback.setback_type()}
          | {:state, ThermostatSetback.setback_state()}
          | {:seq_number, Grizzly.seq_number()}
          | {:retries, non_neg_integer()}

  defstruct type: :no_override,
            state: 0,
            seq_number: nil,
            retries: 2

  @spec init([opt]) :: {:ok, t}
  def init(opts) do
    {:ok, struct(__MODULE__, opts)}
  end

  @spec encode(t) :: {:ok, binary}
  def encode(%__MODULE__{type: type, state: state, seq_number: seq_number}) do
    enc_type = ThermostatSetback.encode_setback_type(type)
    enc_state = ThermostatSetback.encode_setback_state(state)

    binary =
      Packet.header(seq_number) <> <<0x47, 0x01, 0x00::size(6), enc_type::size(2), enc_state>>

    {:ok, binary}
  end

  @spec handle_response(t, Packet.t()) ::
          {:continue, t} | {:done, {:error, :nack_response}} | {:done, :ok} | {:retry, t}
  def handle_response(%__MODULE__{seq_number: seq_number}, %Packet{
        seq_number: seq_number,
        types: [:ack_response]
      }) do
    {:done, :ok}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: 0}, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:done, {:error, :nack_response}}
  end

  def handle_response(%__MODULE__{seq_number: seq_number, retries: n} = command, %Packet{
        seq_number: seq_number,
        types: [:nack_response]
      }) do
    {:retry, %{command | retries: n - 1}}
  end

  def handle_response(command, _), do: {:continue, command}
end
