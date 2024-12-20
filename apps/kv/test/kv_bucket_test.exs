defmodule KV.BucketTest do
  alias KV.Bucket
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = Bucket.start_link([])

    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert Bucket.get(bucket, "milk") == nil

    Bucket.put(bucket, "milk", 3)

    assert Bucket.get(bucket, "milk") == 3
  end

  test "delete values by key", %{bucket: bucket} do
    Bucket.put(bucket, "milk", 3)

    assert Bucket.get(bucket, "milk") == 3

    Bucket.delete(bucket, "milk")

    assert Bucket.get(bucket, "milk") == nil
  end

  test "are temporary workers" do
    assert Supervisor.child_spec(KV.Bucket, []).restart == :temporary
  end
end
