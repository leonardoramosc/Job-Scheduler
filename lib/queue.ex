defmodule JobScheduler.Queue do
  use GenServer

  def start_link(queue_name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(queue_name))
  end

  def create_queue(queue_name) do
    GenServer.call(__MODULE__, {:create_queue, queue_name})
  end

  def list_queues do
    GenServer.call(__MODULE__, :list_queues)
  end

  defp via_tuple(queue_name) do
    {:via, Registry, {JobScheduler.JobsRegistry, queue_name}}
  end

  # Server (callbacks)
  @impl true
  def init(tasks) do
    {:ok, tasks}
  end

  @impl true
  def handle_call({:enqueue, task}, _from, tasks) do
    {:reply, :ok, [task | tasks]}
  end

  @impl true
  def handle_call(:list_tasks,  _from, tasks) do
    {:reply, tasks, tasks}
  end
end
