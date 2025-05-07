defmodule JobScheduler.Application do
  use Application

  def start(_type, message) do
    IO.inspect("#{message}")
    children = [

      JobScheduler.QueueManager,
      {DynamicSupervisor, strategy: :one_for_one, name: JobScheduler.QueuesDynamicSupervisor},
      {Registry, keys: :unique, name: JobScheduler.JobsRegistry},
      {Plug.Cowboy, scheme: :http, plug: HTTPServer, options: [port: 4000]}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
