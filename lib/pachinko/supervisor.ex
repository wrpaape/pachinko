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
    printer =
      Pachinko.Printer
      |> supervisor([spread_and_pad])

    {:ok, _printer_pid} =
      sup_pid
      |> Supervisor.start_child(printer)

    # and then the subsupervisor for the server
    server_sup =
      Pachinko.Server.Supervisor
      |> worker([max_ball_spread])

    {:ok, _server_sup_pid} =
      sup_pid
      |> Supervisor.start_child(server_sup)
  end

  def init(_args) do
    supervise([], strategy: :one_for_one)
  end

  def restart_child(child_pid), do: __MODULE__ |> Supervisor.restart_child(child_pid)
end