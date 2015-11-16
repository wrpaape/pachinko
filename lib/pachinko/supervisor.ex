defmodule Pachinko.Supervisor do
  use Supervisor

  def start_link do
    ok_sup_pid =
      {:ok, sup_pid} =
        __MODULE__
        |> Supervisor.start_link([])

    start_workers(sup_pid)
    ok_sup_pid
  end

  def start_workers(sup_pid) do
    max_ball_spread = fetch_max_ball_spread!

    # Start the server
    server_sup =
      Pachinko.Server
      |> supervisor([max_ball_spread])
    
    {:ok, server_pid} =
      sup_pid
      |> Supervisor.start_child(server_sup)

    # and then the subsupervisor for the printer
    printer =
      Pachinko.Supervisor.Printer
      |> worker([max_ball_spread, server_pid])

    {:ok, _printer_pid} =
      sup_pid
      |> Supervisor.start_child(printer)
  end

  def init(_args) do
    supervise([], strategy: :one_for_all)
  end

  defp fetch_max_ball_spread! do
    {:ok, columns} = :io.columns
    
    columns
    |> div(2)
    |> + 1
    |> div(2)
  end
end