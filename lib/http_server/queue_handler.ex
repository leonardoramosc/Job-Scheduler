defmodule HttpServer.QueueHandler do
  alias JobScheduler.{QueueManager}
  import Plug.Conn

  def create_queue(conn) do
    with {:ok, queue_name} <- Map.fetch(conn.body_params, "queue_name"),
         :ok <- QueueManager.create_queue(queue_name),
         {:ok, response} <- Jason.encode(%{status: "ok", queue_name: queue_name}) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response)
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
end
