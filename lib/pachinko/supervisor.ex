defmodule Pachinko.Supervisor do
  use Supervisor

  def start_link(spread_and_pad) do
    ok_sup_pid =
      {:ok, sup_pid} =
        __MODULE__
        |> Supervisor.start_link([])

    start_workers(sup_pid, spread_and_pad)

    ok_sup_pid
  end

  def start_workers(sup_pid, spread_and_pad = {max_ball_spread, _top_pad}) do
    # Start the server
    server =
      Pachinko.Server
      |> supervisor([max_ball_spread])

    {:ok, _server_pid} =
      sup_pid
      |> Supervisor.start_child(server)

    # and then the subsupervisor for the printer
    printer_sup =
      Pachinko.Printer.Supervisor
      |> worker([spread_and_pad])

    {:ok, _printer_sup_pid} =
      sup_pid
      |> Supervisor.start_child(printer_sup)
  end

  def init(_args) do
    supervise([], strategy: :one_for_all)
  end
end