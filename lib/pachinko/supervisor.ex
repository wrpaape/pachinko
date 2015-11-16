defmodule Pachinko.Supervisor do
  use Supervisor

  def start_link(max_ball_spread) do
    ok_sup_pid =
      {:ok, sup_pid} =
        __MODULE__
        |> Supervisor.start_link([])

    start_workers(sup_pid, max_ball_spread)
    ok_sup_pid
  end

  def start_workers(sup_pid, max_ball_spread) do
    # Start the server
    server =
      Pachinko.Server
      |> supervisor([max_ball_spread])

    {:ok, server_pid} =
      sup_pid
      |> Supervisor.start_child(server)

    # and then the subsupervisor for the printer
    printer_sup =
      Pachinko.Supervisor.Printer
      |> worker([max_ball_spread, server_pid])

    {:ok, _printer_sup_pid} =
      sup_pid
      |> Supervisor.start_child(printer_sup)
  end

  def init(_args) do
    supervise([], strategy: :one_for_all)
  end
end