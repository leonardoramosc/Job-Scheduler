defmodule HTTPServer.QueueHandler do
  alias JobScheduler.{QueueManager, Queue}
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

    changeset = Task.changeset(%Task{}, task_body)

    with {:ok, task} <- validate_changeset_task(changeset),
         :ok <- Queue.enqueue(queue_name, task),
         {:ok, response} <- Jason.encode(%{status: "ok", task: task}) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(201, response)
    else
      {:invalid, changeset} ->
        errors = extract_errors_from_changeset(changeset)
        {response, status_code} = json_response(errors, 422)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status_code, response)

      # TODO: handle error coming from Queue.enqueue
      {:error, error} ->
        IO.inspect(error)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, "internal server error")
    end
  end

  defp validate_changeset_task(changeset) do
    case Ecto.Changeset.apply_action(changeset, :update) do
      {:ok, task} -> {:ok, task}
      {:error, changeset} -> {:invalid, changeset}
    end
  end

  defp extract_errors_from_changeset(changeset) do
    IO.inspect(changeset)

    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, val}, acc ->
        String.replace(acc, "%{#{key}}", to_string(val))
      end)
    end)
  end

  defp json_response(response, status_code) do
    case Jason.encode(response) do
      {:ok, encoded} ->
        {encoded, status_code}

      {:error, error} ->
        IO.inspect(error)
        {"internal server error", 500}
    end
  end
end
