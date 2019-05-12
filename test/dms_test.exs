defmodule DMSTest do
  use ExUnit.Case

  doctest DMS

  test "ping should init a new dms" do
    id = "test-svc"
    assert :pong = DMS.ping(id)
    assert DMS.alive?(id)
  end

  test "ping twice should return ok" do
    import Task, only: [async: 1, await: 1]
    id = "some_id"
    ping = fn -> DMS.ping(id) end

    resps = 1..10
    |> Enum.map(fn _ -> Task.async(ping) end)
    |> Enum.map(fn t -> Task.await(t) end)

    for resp <- resps do
      assert :pong = resp
    end
  end

  test "service should die after the configured interval" do
    id = "test-svc-2"
    assert :pong = DMS.ping(id)
    timeout = Application.fetch_env!(:timeout, :"#{Mix.env()}") + 1
    Process.sleep(timeout)
    refute DMS.alive?(id)
  end
end
