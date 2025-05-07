defmodule HTTPServer do
  alias HTTPServer.{QueueHandler}
  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  post "/api/queue" do
    QueueHandler.create_queue(conn)
  end

  post "/api/queue/:name/task" do
    queue_name = conn.params["name"]
    QueueHandler.create_task(conn, queue_name)
  end

  match _ do
    send_resp(conn, 404, "Ruta no encontrada")
  end
end
