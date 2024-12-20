defmodule KV.Registry do
  use GenServer

  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  def init(server) do
    names = :ets.new(server, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  def lookup(server, name) do
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        {:reply, pid, {names, refs}}

      :error ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.DynamicSupervisor, KV.Bucket)
        ref = Process.monitor(pid)

        :ets.insert(names, {name, pid})
        refs = Map.put(refs, ref, name)
        {:reply, pid, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _resson}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)

    {:noreply, {names, refs}}
  end

  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
