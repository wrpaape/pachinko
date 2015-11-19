defmodule Pachinko.Server.Supervisor do
  use Supervisor

  def start_link(max_ball_spread) do
    ok_sup_pid =
      {:ok, sup_pid} =
        __MODULE__
        |> Supervisor.start_link([])

    {:ok, _server_pid} =
      max_ball_spread
      |> start_server(sup_pid)

    ok_sup_pid
  end

  def start_server(max_ball_spread, sup_pid) do
    server =
      Pachinko.Server
      |> worker([max_ball_spread])
      
    sup_pid
    |> Supervisor.start_child(server)
  end


  def init(_) do
    supervise([], strategy: :one_for_one)
  end
end