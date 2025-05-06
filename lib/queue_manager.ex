defmodule JobScheduler.QueueManager do
  use GenServer

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def create_queue(queue_name) do
    GenServer.call(__MODULE__, {:create_queue, queue_name})
  end

  def list_queues do
    GenServer.call(__MODULE__, :list_queues)
  end

  # Server (callbacks)
  @impl true
  def init(queues) do
    {:ok, queues}
  end

  @impl true
  def handle_call({:create_queue, queue_name}, _from, queues) do
    spec = {JobScheduler.Queue, queue_name}
    case DynamicSupervisor.start_child(JobScheduler.QueuesDynamicSupervisor, spec) do
      {:ok, _child} -> {:reply, :ok, [queue_name | queues]}
      {:error, error} ->
        IO.inspect("unable to create queue. Reason:")
        IO.inspect(error)
      _ -> {:reply, :ok, queues}
    end
  end

  @impl true
  def handle_call(:list_queues,  _from, queues) do
    result = Registry.select(JobScheduler.JobsRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    {:reply, result, queues}
  end
end
