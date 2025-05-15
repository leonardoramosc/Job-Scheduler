defmodule JobScheduler.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:name, :url, :body, :schedule_time, :status, :created_at]}
  @allowed_statuses ~w(active inactive banned)

  schema "tasks" do
    field(:name, :string)
    field(:url, :string)
    field(:body, :map)
    field(:schedule_time, :naive_datetime)
    field(:status)
    field(:created_at)
  end

  def changeset(task, params \\ %{}) do
    task
    |> Map.put(:status, :pending)
    |> cast(params, [:name, :url, :body, :schedule_time])
    |> validate_required([:name, :url, :body, :schedule_time])
    |> validate_inclusion(:status, @allowed_statuses)
    |> validate_format(:url, ~r/^https?:\/\/[^\s]+$/)
    |> validate_map(:body)
    |> validate_future_date(:schedule_time)
  end

  defp validate_future_date(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      today = NaiveDateTime.utc_now()

      case NaiveDateTime.compare(value, today) do
        :gt -> []
        _ -> [{field, "must be a future date"}]
      end
    end)
  end

  defp validate_map(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if is_map(value) do
        []
      else
        [{field, "must be a map"}]
      end
    end)
  end

  def execute(task) do
    IO.inspect("executing task #{task.name}. url: #{task.url}")

    with {:ok, body_str} <- Jason.encode(task.body),
         {:ok, response} <- HTTPoison.post(task.url, body_str, [{"Content-Type", "application/json"}]) do
      IO.inspect("task executed successfully. Response:")
      IO.inspect(response)
      :ok
    else
      {:error, error} ->
        IO.inspect("unable to execute rask. Error:")
        IO.inspect(error)
        :error
    end
  end
end
