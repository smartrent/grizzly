defmodule <%= inspect command_module %> do
  @moduledoc """
  What does this command do??

  Params:

  <%= for p <- params do %>
    * `<%= inspect p %>` - explain what `<%= inspect p %>` param is for
  <% end %>
  """

  @behaviour Grizzly.ZWave.Command

  alias Grizzly.ZWave.Command

  @type param :: # give me some type specs for your params

  @impl true
  @spec new([param()]) :: Command.t()
  def new(params) do
    command = %Command{
      name: <%= inspect command_name %>,
      command_byte: # insert byte here,
      command_class: <%= inspect command_class_module %>,
      params: params,
      impl: __MODULE__
    }

    {:ok, command}
  end

  @impl true
  @spec encode_params(Command.t()) :: binary()
  def encode_params(_command) do
    <<>>
  end

  @impl true
  @spec decode_params(binary()) :: [param()]
  def decode_params(_binary) do
    []
  end
end
