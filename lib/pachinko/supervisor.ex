defmodule Pachinko.Supervisor do
  use Supervisor

  def start_link(columns) do
    ok_pid =
      {:ok, root_sup_pid} =
      Supervisor.start_link(__MODULE__, [])

    start_workers(root_sup_pid, columns)
    ok_pid
  end

  def start_workers(root_sup_pid, columns) do
    # Start the printer worker
    printer =
      Pachinko.Printer
      |> worker([columns])

    {:ok, printer_pid} =
      root_sup_pid
      |> Supervisor.start_child(printer)


    # and then the subsupervisor for the server
    server_sup =
      Pachinko.Supervisor.Server
      |> supervisor([printer_pid])

    root_sup_pid
    |> Supervisor.start_child(server_sup)
  end

  def init(_args) do
    supervise([], strategy: :one_for_one)
  end
end