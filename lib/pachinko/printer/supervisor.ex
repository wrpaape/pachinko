defmodule Pachinko.Printer.Supervisor do
  use Supervisor

  def start_link(spread_and_pad) do
    ok_sup_pid =
      {:ok, sup_pid} =
        __MODULE__
        |> Supervisor.start_link([])

    {:ok, _printer_pid} =
      spread_and_pad
      |> start_printer(sup_pid)

    ok_sup_pid
  end

  def start_printer(spread_and_pad, sup_pid) do
    printer =
      Pachinko.Printer
      |> worker([spread_and_pad])
      
    sup_pid
    |> Supervisor.start_child(printer)
  end


  def init(_) do
    supervise([], strategy: :one_for_one)
  end
end