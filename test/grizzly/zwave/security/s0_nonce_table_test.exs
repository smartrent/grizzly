defmodule Grizzly.ZWave.Security.S0NonceTableTest do
  use ExUnit.Case, async: true

  alias Grizzly.ZWave.Security.S0NonceTable

  test "generate and take", %{test: test} do
    pid = start_supervised!({S0NonceTable, name: test})

    assert {:ok, <<nonce1_1_id::8, _::binary>> = nonce1_1} = S0NonceTable.generate(pid, 1)
    assert {:ok, <<nonce1_2_id::8, _::binary>> = nonce1_2} = S0NonceTable.generate(pid, 1)
    assert {:ok, <<nonce2_1_id::8, _::binary>> = nonce2_1} = S0NonceTable.generate(pid, 2)

    assert nonce1_1 == S0NonceTable.take(pid, 1, nonce1_1_id)
    assert nonce1_2 == S0NonceTable.take(pid, 1, nonce1_2_id)
    assert nonce2_1 == S0NonceTable.take(pid, 2, nonce2_1_id)
    assert nil == S0NonceTable.take(pid, 1, nonce2_1_id)
    assert nil == S0NonceTable.take(pid, 2, nonce1_1_id)
  end

  test "expiration", %{test: test} do
    pid = start_supervised!({S0NonceTable, name: test, ttl: 50})

    assert {:ok, <<nonce1_id::8, _::binary>> = nonce_1} = S0NonceTable.generate(pid, 1)
    assert {:ok, <<nonce2_id::8, _::binary>> = _nonce_2} = S0NonceTable.generate(pid, 1)
    assert {:ok, <<nonce3_id::8, _::binary>> = _nonce_3} = S0NonceTable.generate(pid, 1)

    assert nonce_1 == S0NonceTable.take(pid, 1, nonce1_id)

    Process.sleep(55)

    assert nil == S0NonceTable.take(pid, 1, nonce2_id)
    assert nil == S0NonceTable.take(pid, 1, nonce3_id)

    assert {:ok, _} = S0NonceTable.generate(pid, 1)

    Process.sleep(55)

    S0NonceTable.generate(pid, 1)

    assert 1 == length(:sys.get_state(pid).nonce_table)
  end

  test "not enough randomness", %{test: test} do
    random_fun = fn _ -> <<1::8>> <> :crypto.strong_rand_bytes(7) end
    pid = start_supervised!({S0NonceTable, name: test, random_fun: random_fun})

    assert {:ok, nonce1} = S0NonceTable.generate(pid, 1)
    assert byte_size(nonce1) == 8

    assert {:ok, nonce2} = S0NonceTable.generate(pid, 2)
    assert byte_size(nonce2) == 8

    assert :error = S0NonceTable.generate(pid, 1)
    assert :error = S0NonceTable.generate(pid, 2)
  end
end
