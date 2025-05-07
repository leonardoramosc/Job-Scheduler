defmodule HTTPServer do
  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  post "/api/queue" do
    HttpServer.QueueHandler.create_queue(conn)
  end

  match _ do
    send_resp(conn, 404, "Ruta no encontrada")
  end
end
