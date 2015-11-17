defmodule Pachinko do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications

  def start(_type, max_ball_spread) do
    import Supervisor.Spec, warn: false

    {:ok, _sup_pid} =
      max_ball_spread
      |> Pachinko.Supervisor.start_link
  end

  def generate_slots(max_pos, token) do
    -max_pos..max_pos
    |> Enum.take_every(2)
    |> Enum.map(&{&1, token})
  end

  def generate_slots(max_pos, token, :into_map) do
    max_pos
    |> generate_slots(token)
    |> Enum.into(%{})
  end
end
