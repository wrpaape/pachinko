defmodule Pachinko.Supervisor.Printer do
  use Supervisor

  def start_link(printer_args) do
    {:ok, _printer_sup_pid} =
      __MODULE__
      |> Supervisor.start_link([printer_args])
  end

  def init(max_ball_spread, server_pid) do
    # Start the server worker and supervise it
    Sequence.Printer
    |> worker([max_ball_spread, server_pid])
    |> List.wrap
    |> supervise(strategy: :simple_one_for_one)
  end
end