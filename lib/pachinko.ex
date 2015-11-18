defmodule Pachinko do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications

  def start(_type, [spread_and_pad, frame_interval]) do
    import Supervisor.Spec, warn: false

    ok_sup_pid = 
      {:ok, _sup_pid} =
        spread_and_pad
        |> Pachinko.Supervisor.start_link
    
    frame_interval
    |> Pachinko.Printer.start

    ok_sup_pid
  end

  def reflect_stagger(max), do: -max..max |> Enum.take_every(2)
end
