defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    start_supervised!({KV.Registry, name: context.test})

    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, pid} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(pid, "milk", 1)
    assert KV.Bucket.get(pid, "milk") == 1
  end

  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, pid} = KV.Registry.lookup(registry, "shopping")

    # Stop the bucket with non-normal reason
    Agent.stop(pid, :shutdown)
    # Registry服务收到Agent.stop的消息后，异步处理消息
    # 所以先创建一个同步消息，保证处理掉同步消息之前的消息
    KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
end
