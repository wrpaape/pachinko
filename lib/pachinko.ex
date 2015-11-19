defmodule Pachinko do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications

  def start(_type, [spread_and_pad]) do
    import Supervisor.Spec, warn: false

    # ok_sup_pid = 
      {:ok, _sup_pid} =
        spread_and_pad
        |> Pachinko.Supervisor.start_link
    
    # frame_interval
    # |> Pachinko.Printer.start

    # ok_sup_pid
  end

  def main do
    fetch_frame_interval!
    |> Pachinko.Printer.start
  end

  def reflect_stagger(max), do: -max..max |> Enum.take_every(2)

  defp to_whole_microseconds(seconds_per_frame) do
    seconds_per_frame * 1000
    |> Float.ceil
    |> trunc
  end

  defp fetch_frame_interval! do
    :pachinko
    |> Application.get_env(:frame_rate)
    |> :math.pow(-1) 
    |> to_whole_microseconds
  end
end
