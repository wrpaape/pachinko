defmodule Pachinko.Supervisor.Server do
  use Supervisor

  def start_link(printer_pid) do
    {:ok, _pid} = Supervisor.start_link(__MODULE__, printer_pid)
  end

  def init(stash_pid) do
    child_process = [worker(Sequence.Server, [stash_pid])]
    supervise(child_process, strategy: :one_for_one)
  end
end