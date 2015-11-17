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

  def stagger_reflected(max), do: Enum.take_every(-max..max, 2)
end
