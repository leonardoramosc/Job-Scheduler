defmodule JobScheduler.Queue do
  use GenServer

  # TODO: move this setting to an env
  @interval 1000

  def start_link(queue_name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(queue_name))
  end

  def enqueue(queue_name, name, type, url, body, schedule_time) do
    task = JobScheduler.Task.new(name, type, url, body, schedule_time)

    case Registry.lookup(JobScheduler.JobsRegistry, queue_name) do
      [{pid, _}] ->
        GenServer.call(pid, {:enqueue, task})

      [] ->
        {:error, "queue #{queue_name} does not exist"}
    end
  end

  def list_tasks(queue_name) do
    case Registry.lookup(JobScheduler.JobsRegistry, queue_name) do
      [{pid, _}] ->
        GenServer.call(pid, :list_tasks)

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
    schedule_processing_of_pending_tasks(tasks)
    {:ok, tasks}
  end

  @impl true
  def handle_call({:enqueue, task}, _from, tasks) do
    tasks = [task | tasks]
    schedule_processing_of_pending_tasks(tasks)
    {:reply, :ok, tasks}
  end

  @impl true
  def handle_call(:list_tasks, _from, tasks) do
    {:reply, tasks, tasks}
  end

  @impl true
  def handle_info(:tick, tasks) do
    IO.puts("processing pending tasks...")

    {due_tasks, pending_tasks_for_future} = split_tasks(tasks)

    unsuccessful_tasks =
      due_tasks
      |> Enum.map(&JobScheduler.Task.execute/1)
      |> Enum.filter(&(&1 != :ok))

    pending_tasks_for_future = unsuccessful_tasks ++ pending_tasks_for_future

    schedule_processing_of_pending_tasks(pending_tasks_for_future)
    {:noreply, pending_tasks_for_future}
  end

  # splits list into due tasks and tasks that are schedule for the future
  # return value: {due_tasks, pending_tasks_for_future}
  defp split_tasks(tasks) do
    Enum.split_with(tasks, fn task ->
      DateTime.compare(task.schedule_time, DateTime.utc_now()) in [:lt, :eq]
    end)
  end

  defp schedule_processing_of_pending_tasks([]), do: :ok

  defp schedule_processing_of_pending_tasks([_, _]) do
    Process.send_after(self(), :tick, @interval)
  end
end
