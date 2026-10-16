defmodule Grizzly.NativeMailboxTest do
  use ExUnit.Case, async: true

  alias Grizzly.Backends.Zwrap.Mailbox

  setup do
    parent = self()

    {:ok, mailbox} =
      Mailbox.start_link(
        name: nil,
        per_node: 2,
        capacity: 4,
        grace: 10,
        classify: fn _ -> :sleeping end,
        finish_wake: fn node ->
          send(parent, {:finished_wake, node})
          :ok
        end,
        transmit: fn owner, node, command, ref, attempt, opts ->
          send(parent, {:transmit, owner, node, command, ref, attempt, opts})
          :ok
        end
      )

    Process.unlink(mailbox)
    on_exit(fn -> if Process.alive?(mailbox), do: GenServer.stop(mailbox) end)
    %{mailbox: mailbox}
  end

  defp submit(mailbox, ref, opts \\ []) do
    Mailbox.submit(mailbox, self(), 2, %{command_class: :basic}, ref, make_ref(), opts)
  end

  test "sleeping queue admission, saturation, wake and serialization", %{mailbox: mailbox} do
    a = make_ref()
    b = make_ref()
    assert :ok = submit(mailbox, a)
    assert :ok = submit(mailbox, b)
    assert {:error, :mailbox_full} = submit(mailbox, make_ref())
    refute_receive {:transmit, _, _, _, _, _, _}
    GenServer.cast(mailbox, {:wake, 2})
    assert_receive {:transmit, _, 2, _, ^a, _, _}
    refute_receive {:transmit, _, 2, _, ^b, _, _}
    GenServer.cast(mailbox, {:cancel, {self(), a}})
    assert_receive {:transmit, _, 2, _, ^b, _, _}
    refute_receive {:finished_wake, 2}
    GenServer.cast(mailbox, {:cancel, {self(), b}})
    assert_receive {:finished_wake, 2}
    assert Mailbox.stats(mailbox).pending == 0
  end

  test "queued deadlines expire without radio work", %{mailbox: mailbox} do
    ref = make_ref()
    assert :ok = submit(mailbox, ref, timeout: 10)
    assert_receive {:backend_failure, ^ref, _, :mailbox_expired}
    refute_receive {:transmit, _, _, _, _, _, _}
    assert Mailbox.stats(mailbox).expired == 1
  end

  test "awake leases delay no-more-information and expire", %{mailbox: mailbox} do
    assert {:ok, _lease} = GenServer.call(mailbox, {:hold, 2, self(), 50})
    GenServer.cast(mailbox, {:wake, 2})
    refute_receive {:finished_wake, 2}, 20
    assert_receive {:finished_wake, 2}
  end

  test "owner death cancels queued work", %{mailbox: mailbox} do
    owner =
      spawn(fn ->
        receive do
          :stop -> :ok
        end
      end)

    assert :ok =
             Mailbox.submit(
               mailbox,
               owner,
               2,
               %{command_class: :basic},
               make_ref(),
               make_ref(),
               []
             )

    Process.exit(owner, :kill)
    wait_empty(mailbox)
    GenServer.cast(mailbox, {:wake, 2})
    assert_receive {:finished_wake, 2}
    refute_receive {:transmit, _, _, _, _, _, _}
  end

  defp wait_empty(mailbox, tries \\ 100)
  defp wait_empty(_mailbox, 0), do: flunk("mailbox did not clean owner")

  defp wait_empty(mailbox, tries) do
    if Mailbox.stats(mailbox).pending != 0 do
      Process.sleep(1)
      wait_empty(mailbox, tries - 1)
    end
  end
end
