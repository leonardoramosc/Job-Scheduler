defmodule JobScheduler.Task do
  defstruct [:name, :created_at, :schedule_time, :status, :type, :url, :body]

  def new(name, type, url, body, schedule_time) do
    %__MODULE__{
      name: name,
      type: type,
      url: url,
      body: body,
      schedule_time: schedule_time,
      status: :pending,
      created_at: DateTime.utc_now()
    }
  end

  def execute(task) do
    HTTPoison.post(task.url, task.body)
    IO.puts("executing task #{task.name}")
    :ok
  end
end
