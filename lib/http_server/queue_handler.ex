defmodule HTTPServer.QueueHandler do
  alias JobScheduler.{QueueManager}
  alias JobScheduler.{Task}
  import Plug.Conn

  def create_queue(conn) do
    with {:ok, queue_name} <- Map.fetch(conn.body_params, "queue_name"),
         :ok <- QueueManager.create_queue(queue_name),
         {:ok, response} <- Jason.encode(%{status: "ok", queue_name: queue_name}) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(201, response)
    else
      :error ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, "queue_name is required")

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, "internal server error")
    end
  end

  def create_task(conn, queue_name) do
    task_body = conn.body_params

    case validate_task(task_body) do
      {:ok, task} ->
        {:ok, response} = Map.from_struct(task) |> Jason.encode()

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, response)

      err ->
        IO.inspect(err)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, "failure")
    end
  end

  defp validate_task(task) do
    # TODO: improve this logic
    missing_keys =
      %Task{}
      |> Map.from_struct()
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.keys()
      |> Enum.reduce([], fn key, acc ->
        unless Map.get(task, key) do
          [key | acc]
        end
        acc
      end)

    unless Enum.empty?(missing_keys) do
      {:error, missing_keys}
    else
      case DateTime.from_iso8601(task["schedule_time"]) do
        {:ok, schedule_time, _} ->
          {:ok, Task.new(task["name"], task["type"], task["url"], task["body"], schedule_time)}

        invalid_date_error ->
          invalid_date_error
      end
    end
  end
end
