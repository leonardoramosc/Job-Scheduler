defmodule JobScheduler.Queue do
  use GenServer

  def start_link(queue_name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(queue_name))
  end

  def enqueue(queue_name, task) do
    case Registry.lookup(JobScheduler.JobsRegistry, queue_name) do
      [{pid, _}] -> GenServer.call(pid, {:enqueue, task})
      [] ->
        {:error, "queue #{queue_name} does not exist"}
    end
  end

  def list_tasks(queue_name) do
    case Registry.lookup(JobScheduler.JobsRegistry, queue_name) do
      [{pid, _}] -> GenServer.call(pid, :list_tasks)
      [] ->
        {:error, "queue #{queue_name} does not exist"}
    end
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
