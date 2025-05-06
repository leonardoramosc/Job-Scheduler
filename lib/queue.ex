defmodule JobScheduler.Queue do
  use GenServer

  @interval 1000 # TODO: move this setting to an env

  def start_link(queue_name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(queue_name))
  end

  def enqueue(queue_name, name, type, body, schedule_time) do
    task = JobScheduler.Task.new(name, type, body, schedule_time)
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
    schedule_processing_of_pending_tasks()
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

  @impl true
  def handle_info(:tick, tasks) do
    {due_tasks, pending_tasks} = Enum.split_with(tasks, fn task -> DateTime.compare(task.schedule_time, DateTime.utc_now()) in [:lt, :eq] end)

    unsuccessful_tasks = due_tasks
    |> Enum.each(&JobScheduler.Task.execute/1)
    |> Enum.filter(&(&1 != :ok))

    schedule_processing_of_pending_tasks()
    {:noreply, [unsuccessful_tasks ++ pending_tasks]}
  end

  defp schedule_processing_of_pending_tasks do
    Process.send_after(self(), :tick, @interval)
  end
end
