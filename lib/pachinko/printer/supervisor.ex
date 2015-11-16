defmodule Pachinko.Printer.Supervisor do
  use Supervisor

  def start_link(max_ball_spread, server_pid) do
    ok_sup_pid =
      {:ok, sup_pid} =
        __MODULE__
        |> Supervisor.start_link([])

    {:ok, _printer_pid} =
      max_ball_spread
      |> start_printer(server_pid, sup_pid)

    ok_sup_pid
  end

  def start_printer(max_ball_spread, server_pid, sup_pid) do
    printer =
      Pachinko.Printer
      |> worker([max_ball_spread, server_pid])
      
    sup_pid
    |> Supervisor.start_child(printer)
  end


  def init(_) do
    supervise([], strategy: :one_for_one)
  end
end