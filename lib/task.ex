defmodule JobScheduler.Task do
  defstruct [:name, :created_at, :schedule_time, :status, :type, :body]

  def new(name, type, body, schedule_time) do
    %__MODULE__{
      name: name,
      type: type,
      body: body,
      schedule_time: schedule_time,
      status: :pending,
      created_at: DateTime.utc_now()
    }
  end

  def execute(task) do
    IO.puts("executing task #{task.name}")
    :ok
  end
end
