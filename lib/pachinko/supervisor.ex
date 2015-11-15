defmodule Sequence.Supervisor do
  use Supervisor

  def start_link(columns) do
    result = {:ok, sup} = Supervisor.start_link(__MODULE__, [columns])
    start_workers(sup, columns)
    result
  end

  def start_workers(sup, initial_number) do
    # Start the printer worker
    {:ok, stash_pid} =
      Supervisor.start_child(sup, worker(Sequence.Printer, [initial_number]))
      # and then the subsupervisor for the actual server
      Supervisor.start_child(sup, supervisor(Sequence.SubSupervisor, [stash_pid]))
  end

  def init(_) do
    supervise([], strategy: :one_for_one)
  end
end